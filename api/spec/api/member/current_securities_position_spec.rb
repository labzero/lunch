require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'member current_securities_position' do
    let(:securities) do
      new_array = []
      securities = JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'securities.json')))
      securities.each do |security|
        security[:SSX_ORIGINAL_PAR] = (rand(0..1000000) + rand).round(2)
        security[:SSX_CURRENT_PAR] = (rand(0..1000000) + rand).round(2)
        security[:SSX_MARKET_VALUE] = (rand(0..1000000) + rand).round(2)
        new_array << security.with_indifferent_access
      end
      new_array
    end
    let(:total_original_par) { securities.inject(0) {|sum, security| sum + security[:SSX_ORIGINAL_PAR]} }
    let(:total_current_par) { securities.inject(0) {|sum, security| sum + security[:SSX_CURRENT_PAR]} }
    let(:total_market_value) { securities.inject(0) {|sum, security| sum + security[:SSX_MARKET_VALUE]} }
    let(:member_current_securities_position) { MAPI::Services::Member::CurrentSecuritiesPosition.current_securities_position(subject, MEMBER_ID) }
    let(:formatted_securities) { double('an array of securities') }

    %w(all pledged unpledged).each do |type|
      it "calls the current_securities_method when the endpoint is hit with a `custody_account_type` of #{type}" do
        expect(MAPI::Services::Member::CurrentSecuritiesPosition).to receive(:current_securities_position).and_return('a response')
        get "/member/#{MEMBER_ID}/current_securities_position/#{type}"
        expect(last_response.status).to eq(200)
      end
    end
    it 'returns a 400 if the endpoint is hit with a `custody_account_type` other than `all`, `pledged` or `unpledged`' do
      get "/member/#{MEMBER_ID}/current_securities_position/foo"
      expect(last_response.status).to eq(400)
    end
    it 'returns a 404 if the endpoint returns a blank result' do
      expect(MAPI::Services::Member::CurrentSecuritiesPosition).to receive(:current_securities_position).and_return(nil)
      get "/member/#{MEMBER_ID}/current_securities_position/all"
      expect(last_response.status).to eq(404)
    end

    [:test, :production].each do |env|
      describe "`current_securities_method` method in the #{env} environment" do
        let(:securities_result_set) {double('Oracle Result Set', fetch_hash: nil)} if env == :production
        let(:securities_result) {[securities[0], securities[1], securities[2], securities[3], securities[4], nil]} if env == :production

        before do
          allow(MAPI::Services::Member::CurrentSecuritiesPosition::Private).to receive(:fake_securities).and_return(securities)
          if env == :production
            allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
            expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(securities_result_set)
            allow(securities_result_set).to receive(:fetch_hash).and_return(*securities_result)
          end
        end

        it 'returns an object with an `as_of_date`' do
          expect(member_current_securities_position[:as_of_date]).to be_kind_of(Date)
        end
        it "returns an object with a `total_net_amount` that is the sum of the individual projection's CPJ_TOTAL_AMOUNT" do
          expect(member_current_securities_position[:total_original_par]).to eq(total_original_par)
        end
        it "returns an object with a `total_principal` that is the sum of the individual projection's CPJ_PRINCIPAL_AMOUNT" do
          expect(member_current_securities_position[:total_current_par]).to eq(total_current_par)
        end
        it "returns an object with a `total_interest` that is the sum of the individual projection's CPJ_INTEREST_AMOUNT" do
          expect(member_current_securities_position[:total_market_value]).to eq(total_market_value)
        end
        it 'returns an object with an array of formatted `securities`' do
          expect(MAPI::Services::Member::CurrentSecuritiesPosition::Private).to receive(:format_securities).with(securities).and_return(formatted_securities)
          expect(member_current_securities_position[:securities]).to eq(formatted_securities)
        end
      end
    end

    describe 'private methods' do
      describe '`format_securities` method' do
        let(:formatted_securities) { MAPI::Services::Member::CurrentSecuritiesPosition::Private.format_securities(securities) }
        date_properties = [:maturity_date, :factor_date, :price_date]
        string_properties = [:custody_account_number, :custody_account_type, :security_pledge_type, :cusip, :description, :reg_id, :pool_number]
        float_properties = [:coupon_rate, :original_par, :factor, :current_par, :price, :market_value]

        date_properties.each do |property|
          it "returns an object with a `#{property}` formatted as a date" do
            formatted_securities.each do |security|
              expect(security[property]).to be_kind_of(Date)
            end
          end
        end
        string_properties.each do |property|
          it "returns an object with a `#{property}` formatted as a string" do
            formatted_securities.each do |security|
              expect(security[property]).to be_kind_of(String)
            end
          end
        end
        float_properties.each do |property|
          it "returns an object with a `#{property}` formatted as a float" do
            formatted_securities.each do |security|
              expect(security[property]).to be_kind_of(Float)
            end
          end
        end
        describe 'handling nil values' do
          (date_properties + string_properties + float_properties).flatten.each do |property|
            it "returns an object with a nil value for `#{property}` if that property doesn't have a value" do
              MAPI::Services::Member::CurrentSecuritiesPosition::Private.format_securities([{}, {}]).each do |security|
                expect(security[property]).to be_nil
              end
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

      describe '`fake_securities` method' do
        let(:fake_securities) { MAPI::Services::Member::CurrentSecuritiesPosition::Private.fake_securities(MEMBER_ID, Time.zone.now.to_date, 'all') }

        it 'returns an array of fake security objects with the appropriate keys' do
          fake_securities.each do |security|
            %i(FHLB_ID ACCOUNT_TYPE SSX_BTC_DATE ADX_BTC_ACCOUNT_NUMBER SSD_SECURITY_PLEDGE_TYPE SSK_CUSIP SSK_DESC1 SSX_REG_ID SSK_POOL_NUMBER SSX_COUPON_RATE SSK_MATURITY_DATE SSX_ORIGINAL_PAR SSX_CURRENT_FACTOR SSX_CUR_FACTOR_DATE SSX_CURRENT_PAR SSX_PRICE SSX_PRICE_DATE SSX_MARKET_VALUE).each do |property|
              expect(security[property]).to_not be_nil
            end
          end
        end
      end
    end
  end
end
