require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'member cash projections' do
    let(:as_of_date) { date = double('A Date'); allow(date).to receive(:to_date).and_return(date); date }
    let(:projections) do
      new_array = []
      projections = JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'cash_projections.json')))
      projections.each do |projection|
        projection[:CPJ_PRINCIPAL_AMOUNT] = (rand(0..1000000) + rand).round(2)
        projection[:CPJ_INTEREST_AMOUNT] = (rand(0..1000000) + rand).round(2)
        projection[:CPJ_TOTAL_AMOUNT] = (rand(0..1000000) + rand).round(2)
        new_array << projection.with_indifferent_access
      end
      new_array
    end
    let(:cpj_total_sum) { projections.inject(0) {|sum, projection| sum + projection[:CPJ_TOTAL_AMOUNT]} }
    let(:cpj_total_principal) { projections.inject(0) {|sum, projection| sum + projection[:CPJ_PRINCIPAL_AMOUNT]} }
    let(:cpj_total_interest) { projections.inject(0) {|sum, projection| sum + projection[:CPJ_INTEREST_AMOUNT]} }
    let(:member_cash_projections) { MAPI::Services::Member::CashProjections.cash_projections(subject, MEMBER_ID) }
    let(:formatted_projections) { double('an array of projections') }

    it 'calls the proper method when the endpoint is hit' do
      expect(MAPI::Services::Member::CashProjections).to receive(:cash_projections)
      get "/member/#{MEMBER_ID}/cash_projections"
    end

    [:test, :production].each do |env|
      describe "`member_cash_projections` method in the #{env} environment" do
        let(:as_of_date_result_set) {double('Oracle Result Set', fetch: nil)} if env == :production
        let(:cash_projections_result_set) {double('Oracle Result Set', fetch_hash: nil)} if env == :production
        let(:as_of_date_result) {[[as_of_date], nil]} if env == :production
        let(:cash_projections_result) {[projections[0], projections[1], projections[2], nil]} if env == :production

        before do
          allow(MAPI::Services::Member::CashProjections::Private).to receive(:fake_cash_projections).and_return(projections)
          allow(MAPI::Services::Member::CashProjections::Private).to receive(:fake_as_of_date).and_return(as_of_date)
          if env == :production
            allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
            expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(as_of_date_result_set)
            expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(cash_projections_result_set)
            allow(as_of_date_result_set).to receive(:fetch).and_return(*as_of_date_result)
            allow(cash_projections_result_set).to receive(:fetch_hash).and_return(*cash_projections_result)
          end
        end

        it 'returns an object with an `as_of_date`' do
          expect(member_cash_projections[:as_of_date].to_date).to eq(as_of_date)
        end
        it "returns an object with a `total_net_amount` that is the sum of the individual projection's CPJ_TOTAL_AMOUNT" do
          expect(member_cash_projections[:total_net_amount]).to eq(cpj_total_sum)
        end
        it "returns an object with a `total_principal` that is the sum of the individual projection's CPJ_PRINCIPAL_AMOUNT" do
          expect(member_cash_projections[:total_principal]).to eq(cpj_total_principal)
        end
        it "returns an object with a `total_interest` that is the sum of the individual projection's CPJ_INTEREST_AMOUNT" do
          expect(member_cash_projections[:total_interest]).to eq(cpj_total_interest)
        end
        it 'returns an object with an array of formatted `projections`' do
          expect(MAPI::Services::Member::CashProjections::Private).to receive(:format_projections).with(projections).and_return(formatted_projections)
          expect(member_cash_projections[:projections]).to eq(formatted_projections)
        end
      end
    end

    describe 'private methods' do
      describe '`format_projections` method' do
        let(:formatted_projections) { MAPI::Services::Member::CashProjections::Private.format_projections(projections) }

        [:settlement_date, :maturity_date].each do |property|
          it "returns an object with a `#{property}` formatted as a date" do
            formatted_projections.each do |projection|
              expect(projection[property]).to be_kind_of(Date)
            end
          end
        end
        [:custody_account, :cusip, :description, :transaction_code, :pool_number].each do |property|
          it "returns an object with a `#{property}` formatted as a string" do
            formatted_projections.each do |projection|
              expect(projection[property]).to be_kind_of(String)
            end
          end
        end
        [:original_par, :coupon_rate, :principal, :interest, :total].each do |property|
          it "returns an object with a `#{property}` formatted as a float" do
            formatted_projections.each do |projection|
              expect(projection[property]).to be_kind_of(Float)
            end
          end
        end
      end

      describe '`fake_as_of_date` method' do
        let(:fake_as_of_date) { MAPI::Services::Member::CashProjections::Private.fake_as_of_date }

        it 'should always return a weekday' do
          expect(fake_as_of_date.wday).to be_between(1,5)
        end
      end

      describe '`fake_cash_projections` method' do
        let(:fake_cash_projections) { MAPI::Services::Member::CashProjections::Private.fake_cash_projections(Time.zone.now.to_date) }

        it 'returns an array of fake cash_projection objects with the appropriate keys' do
          fake_cash_projections.each do |projection|
            %i(CPJ_SETTLE_DATE CPJ_BTC_ACCOUNT_NUMBER CPJ_CUSIP CPJ_DESC_LINE_1 CPJ_TRANS_CODE CPJ_POOL_ID CPJ_UNITS CPJ_ISSUE_RATE CPJ_MATURITY_DATE CPJ_PRINCIPAL_AMOUNT CPJ_INTEREST_AMOUNT CPJ_TOTAL_AMOUNT).each do |property|
              expect(projection[property]).to_not be_nil
            end
          end
        end
      end
    end
  end
end
