require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  %w(current monthly).each do |report_type|
    describe "the #{report_type}_securities_position endpoint" do
      let(:securities) do
        new_array = []
        securities = JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'securities.json')))
        securities.each do |security|
          security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:original_par][report_type].to_s] = (rand(0..1000000) + rand).round(2)
          security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:current_par][report_type]] = (rand(0..1000000) + rand).round(2)
          security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:market_value][report_type]] = (rand(0..1000000) + rand).round(2)
          new_array << security.with_indifferent_access
        end
        new_array
      end
      let(:total_original_par) { securities.inject(0) {|sum, security| sum + security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:original_par][report_type]]} }
      let(:total_current_par) { securities.inject(0) {|sum, security| sum + security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:current_par][report_type]]} }
      let(:total_market_value) { securities.inject(0) {|sum, security| sum + security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:market_value][report_type]]} }
      let(:formatted_securities) { double('an array of securities') }
      if report_type == 'current'
        let(:member_securities_position) { MAPI::Services::Member::SecuritiesPosition.securities_position(subject, MEMBER_ID, report_type) }
      else
        let(:member_securities_position) { MAPI::Services::Member::SecuritiesPosition.securities_position(subject, MEMBER_ID, report_type, {start_date: '2015-01-01', end_date: '2015-01-31', custody_account_type: nil}) }

        it 'calls the `securities_position` method with a start_date and end_date corresponding to the `month_end_date` param' do
          month_end_date = rand(365).days.ago(Date.today).strftime('%Y-%m-%d')
          start_date = month_end_date.to_date.beginning_of_month.strftime('%Y-%m-%d')
          end_date = month_end_date.to_date.end_of_month.strftime('%Y-%m-%d')
          expect(MAPI::Services::Member::SecuritiesPosition).to receive(:securities_position).with(an_instance_of(MAPI::ServiceApp), MEMBER_ID.to_s, report_type.to_sym, {start_date: start_date, end_date: end_date, custody_account_type: nil})
          get "/member/#{MEMBER_ID}/monthly_securities_position/#{month_end_date}/all"
        end
        it 'returns a 400 if the `month_end_date` is not properly formatted' do
          get "/member/#{MEMBER_ID}/monthly_securities_position/foo/all"
          expect(last_response.status).to eq(400)
        end
      end
      %w(all pledged unpledged).each do |type|
        it "calls the current_securities_method when the endpoint is hit with a `custody_account_type` of #{type}" do
          allow(MAPI::Services::Member::SecuritiesPosition).to receive(:securities_position).and_return('a response')
          if report_type == 'current'
            get "/member/#{MEMBER_ID}/current_securities_position/#{type}"
          else
            get "/member/#{MEMBER_ID}/monthly_securities_position/2015-01-31/#{type}"
          end
          expect(last_response.status).to eq(200)
        end
      end
      it 'returns a 400 if the endpoint is hit with a `custody_account_type` other than `all`, `pledged` or `unpledged`' do
        if report_type == 'current'
          get "/member/#{MEMBER_ID}/current_securities_position/foo"
        else
          get "/member/#{MEMBER_ID}/monthly_securities_position/2015-01-31/foo"
        end
        expect(last_response.status).to eq(400)
      end

      [:test, :production].each do |env|
        describe "`current_securities_method` method in the #{env} environment" do
          let(:securities_result_set) {double('Oracle Result Set', fetch_hash: nil)} if env == :production
          let(:securities_result) {[securities[0], securities[1], securities[2], securities[3], securities[4], nil]} if env == :production

          before do
            allow(MAPI::Services::Member::SecuritiesPosition::Private).to receive(:fake_securities).and_return(securities)
            if env == :production
              allow(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
              allow(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(securities_result_set)
              allow(securities_result_set).to receive(:fetch_hash).and_return(*securities_result)
            end
          end

          it 'returns an object with an `as_of_date`' do
            expect(member_securities_position[:as_of_date]).to be_kind_of(Date)
          end
          it "returns an object with a `total_original_par` that is the sum of the individual projection's original pars" do
            expect(member_securities_position[:total_original_par]).to eq(total_original_par)
          end
          it "returns an object with a `total_current_par` that is the sum of the individual projection's current pars" do
            expect(member_securities_position[:total_current_par]).to eq(total_current_par)
          end
          it "returns an object with a `total_market_value` that is the sum of the individual projection's market values" do
            expect(member_securities_position[:total_market_value]).to eq(total_market_value)
          end
          it 'returns an object with an array of formatted `securities`' do
            allow(MAPI::Services::Member::SecuritiesPosition::Private).to receive(:format_securities).and_return(formatted_securities)
            expect(member_securities_position[:securities]).to eq(formatted_securities)
          end
        end
      end
      describe 'private methods' do
        describe '`format_securities` method' do
          let(:formatted_securities) { MAPI::Services::Member::SecuritiesPosition::Private.format_securities(securities, :current) }

          [:maturity_date, :factor_date, :price_date].each do |property|
            it "returns an object with a `#{property}` formatted as a date" do
              formatted_securities.each do |security|
                expect(security[property]).to be_kind_of(Date)
              end
            end
          end
          [:custody_account_number, :custody_account_type, :security_pledge_type, :cusip, :description, :reg_id, :pool_number].each do |property|
            it "returns an object with a `#{property}` formatted as a string" do
              formatted_securities.each do |security|
                expect(security[property]).to be_kind_of(String)
              end
            end
          end
          [:coupon_rate, :original_par, :factor, :current_par, :price, :market_value].each do |property|
            it "returns an object with a `#{property}` formatted as a float" do
              formatted_securities.each do |security|
                expect(security[property]).to be_kind_of(Float)
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
          let(:fake_securities) { MAPI::Services::Member::SecuritiesPosition::Private.fake_securities(MEMBER_ID, Time.zone.now.to_date, :current, nil) }

          it 'returns an array of fake security objects with the appropriate keys' do
            fake_securities.each do |security|
              %i(FHLB_ID ACCOUNT_TYPE SSX_BTC_DATE ADX_BTC_ACCOUNT_NUMBER SSD_SECURITY_PLEDGE_TYPE SSK_CUSIP SSK_DESC1 SSX_REG_ID SSK_POOL_NUMBER SSX_COUPON_RATE SSK_MATURITY_DATE SSX_ORIGINAL_PAR SSX_CURRENT_FACTOR SSX_CUR_FACTOR_DATE SSX_CURRENT_PAR SSX_PRICE SSX_PRICE_DATE SSX_MARKET_VALUE).each do |property|
                expect(security[property]).to_not be_nil
              end
            end
          end
          %w(U P).each do |account_type|
            it "returns fake securities with an `ACCOUNT_TYPE` of #{account_type} when #{account_type} is passed in as the `custody_account_type` arg" do
              results = MAPI::Services::Member::SecuritiesPosition::Private.fake_securities(MEMBER_ID, Time.zone.now.to_date, :current, account_type)
              results.each do |result|
                expect(result['ACCOUNT_TYPE']).to eq(account_type)
              end
            end
          end
          it 'returns fake securities with an `ACCOUNT_TYPE` of either `U` or `P` when no `custody_account_type` arg is given' do
            results = MAPI::Services::Member::SecuritiesPosition::Private.fake_securities(MEMBER_ID, Time.zone.now.to_date, :current, nil)
            results.each do |result|
              expect(['U', 'P']).to include(result['ACCOUNT_TYPE'])
            end
          end
        end
      end
    end
  end
end
