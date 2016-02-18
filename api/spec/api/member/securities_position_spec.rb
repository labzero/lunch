require 'spec_helper'

describe MAPI::ServiceApp do

  RSpec.shared_examples 'a securities position with `total_original_par`, `total_current_par` and `total_market_value`' do |env, report_type, endpoint_arg|
    describe 'object properties that sum other values' do
      let(:call_method) { MAPI::Services::Member::SecuritiesPosition.securities_position(subject, member_id, endpoint_arg) }
      let(:securities) do
        new_array = []
        securities = JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'securities.json')))
        securities.each do |security|
          security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:original_par][report_type]] = (rand(0..1000000) + rand).round(2)
          security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:current_par][report_type]] = (rand(0..1000000) + rand).round(2)
          security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:market_value][report_type]] = (rand(0..1000000) + rand).round(2)
          new_array << security.with_indifferent_access
        end
        new_array
      end
      let(:total_original_par) { securities.inject(0) {|sum, security| sum + security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:original_par][report_type]]} }
      let(:total_current_par) { securities.inject(0) {|sum, security| sum + security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:current_par][report_type]]} }
      let(:total_market_value) { securities.inject(0) {|sum, security| sum + security[MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS[:market_value][report_type]]} }

      before do
        if env == :production
          allow(securities_result_set).to receive(:fetch_hash).and_return(*(securities + [nil]))
        else
          allow(MAPI::Services::Member::SecuritiesPosition::Private).to receive(:fake_securities).and_return(securities)
        end
      end

      it "returns an object with a `total_original_par` that is the sum of the individual projection's original pars" do
        expect(call_method[:total_original_par]).to eq(total_original_par)
      end
      it "returns an object with a `total_current_par` that is the sum of the individual projection's current pars" do
        expect(call_method[:total_current_par]).to eq(total_current_par)
      end
      it "returns an object with a `total_market_value` that is the sum of the individual projection's market values" do
        expect(call_method[:total_market_value]).to eq(total_market_value)
      end
    end
  end

  %w(current monthly).each do |report_type|
    describe "the #{report_type}_securities_position endpoint" do
      let(:securities) { JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'securities.json'))) }
      let(:formatted_securities) { double('an array of securities', sum: nil) }
      if report_type == 'current'
        let(:member_securities_position) { MAPI::Services::Member::SecuritiesPosition.securities_position(subject, member_id, report_type) }
      else
        let(:member_securities_position) { MAPI::Services::Member::SecuritiesPosition.securities_position(subject, member_id, report_type, {start_date: '2015-01-01', end_date: '2015-01-31', custody_account_type: nil}) }

        it 'calls the `securities_position` method with a start_date and end_date corresponding to the `month_end_date` param' do
          month_end_date = rand(365).days.ago(Time.zone.today).strftime('%Y-%m-%d')
          start_date = month_end_date.to_date.beginning_of_month.strftime('%Y-%m-%d')
          end_date = month_end_date.to_date.end_of_month.strftime('%Y-%m-%d')
          expect(MAPI::Services::Member::SecuritiesPosition).to receive(:securities_position).with(an_instance_of(MAPI::ServiceApp), member_id.to_s, report_type.to_sym, {start_date: start_date, end_date: end_date, custody_account_type: nil})
          get "/member/#{member_id}/monthly_securities_position/#{month_end_date}/all"
        end
        it 'returns a 400 if the `month_end_date` is not properly formatted' do
          get "/member/#{member_id}/monthly_securities_position/foo/all"
          expect(last_response.status).to eq(400)
        end
      end
      %w(all pledged unpledged).each do |type|
        it "calls the current_securities_method when the endpoint is hit with a `custody_account_type` of #{type}" do
          allow(MAPI::Services::Member::SecuritiesPosition).to receive(:securities_position).and_return('a response')
          if report_type == 'current'
            get "/member/#{member_id}/current_securities_position/#{type}"
          else
            get "/member/#{member_id}/monthly_securities_position/2015-01-31/#{type}"
          end
          expect(last_response.status).to eq(200)
        end
      end
      it 'returns a 400 if the endpoint is hit with a `custody_account_type` other than `all`, `pledged` or `unpledged`' do
        if report_type == 'current'
          get "/member/#{member_id}/current_securities_position/foo"
        else
          get "/member/#{member_id}/monthly_securities_position/2015-01-31/foo"
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

          it_behaves_like 'a securities position with `total_original_par`, `total_current_par` and `total_market_value`', env, report_type, report_type
          it 'returns an object with an `as_of_date`' do
            expect(member_securities_position[:as_of_date]).to be_kind_of(Date)
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
            it "uses `dateify` to parse `#{property}`" do
              securities.each do |security|
                expect(MAPI::Services::Member::SecuritiesPosition::Private).to receive(:dateify).with(security[property]) if security[property]
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
          let(:fake_securities) { MAPI::Services::Member::SecuritiesPosition::Private.fake_securities(member_id, Time.zone.now.to_date, :current, nil) }

          it 'returns an array of fake security objects with the appropriate keys' do
            fake_securities.each do |security|
              %i(FHLB_ID ACCOUNT_TYPE SSX_BTC_DATE ADX_BTC_ACCOUNT_NUMBER SSD_SECURITY_PLEDGE_TYPE SSK_CUSIP SSK_DESC1 SSX_REG_ID SSK_POOL_NUMBER SSX_COUPON_RATE SSK_MATURITY_DATE SSX_ORIGINAL_PAR SSX_CURRENT_FACTOR SSX_CUR_FACTOR_DATE SSX_CURRENT_PAR SSX_PRICE SSX_PRICE_DATE SSX_MARKET_VALUE).each do |property|
                expect(security[property]).to_not be_nil
              end
            end
          end
          %w(U P).each do |account_type|
            it "returns fake securities with an `ACCOUNT_TYPE` of #{account_type} when #{account_type} is passed in as the `custody_account_type` arg" do
              results = MAPI::Services::Member::SecuritiesPosition::Private.fake_securities(member_id, Time.zone.now.to_date, :current, account_type)
              results.each do |result|
                expect(result['ACCOUNT_TYPE']).to eq(account_type)
              end
            end
          end
          it 'returns fake securities with an `ACCOUNT_TYPE` of either `U` or `P` when no `custody_account_type` arg is given' do
            results = MAPI::Services::Member::SecuritiesPosition::Private.fake_securities(member_id, Time.zone.now.to_date, :current, nil)
            results.each do |result|
              expect(['U', 'P']).to include(result['ACCOUNT_TYPE'])
            end
          end
        end
      end
    end
  end

  describe 'the managed_securities endpoint' do
    let(:call_endpoint) { get "/member/#{member_id}/managed_securities" }
    let(:managed_securities_response) { double('result of `managed_securities`', to_json: nil) }
    it 'calls the `managed_securities` method' do
      expect(MAPI::Services::Member::SecuritiesPosition).to receive(:securities_position).and_return(managed_securities_response)
      call_endpoint
    end
    it 'returns json' do
      allow(MAPI::Services::Member::SecuritiesPosition).to receive(:securities_position).and_return(managed_securities_response)
      expect(managed_securities_response).to receive(:to_json)
      call_endpoint
    end
  end
  describe 'the `securities_position` method with a report type of :managed' do
    [:test, :production].each do |env|
      describe "`current_securities_method` method in the #{env} environment" do
        managed_security_fields = %i(eligibility authorized_by borrowing_capacity)
        let(:managed_securities) { MAPI::Services::Member::SecuritiesPosition.securities_position(subject, member_id, :managed) }
        let(:securities) { JSON.parse(File.read(File.join(MAPI.root, 'spec', 'fixtures', 'securities.json'))) }
        let(:securities_result_set) {double('Oracle Result Set', fetch_hash: nil)}

        before do
          allow(MAPI::ServiceApp).to receive(:environment).and_return(env)
          if env == :production
            allow(ActiveRecord::Base.connection).to receive(:execute).and_return(securities_result_set)
            allow(securities_result_set).to receive(:fetch_hash).and_return(*(securities + [nil]))
          else
            allow(MAPI::Services::Member::SecuritiesPosition::Private).to receive(:fake_securities).and_return(securities)
          end
        end
        it_behaves_like 'a securities position with `total_original_par`, `total_current_par` and `total_market_value`', env, :current, :managed
        if env == :production
          describe 'executing the SQL query' do
            it 'selects the proper fields' do
              select_statement = "SELECT SSX_BTC_DATE, #{MAPI::Services::Member::SecuritiesPosition::SECURITIES_FIELD_MAPPINGS.collect{|key, value| value[:current].to_s}.join(',')}"
              expect(ActiveRecord::Base.connection).to receive(:execute).with(a_string_including(select_statement)).and_return(securities_result_set)
              managed_securities
            end
            it 'pulls from the proper table' do
              from_statement = 'FROM SAFEKEEPING.SSK_INTRADAY_SEC_POSITION'
              expect(ActiveRecord::Base.connection).to receive(:execute).with(a_string_including(from_statement)).and_return(securities_result_set)
              managed_securities
            end
            it 'it includes the proper WHERE modifier' do
              where_statement = "fhlb_id = #{member_id}"
              expect(ActiveRecord::Base.connection).to receive(:execute).with(a_string_including(where_statement)).and_return(securities_result_set)
              managed_securities
            end
          end
        end
        it 'returns an object with an `as_of_date`' do
          expect(managed_securities[:as_of_date]).to be_kind_of(Date)
        end
        it 'formats the securities' do
          expect(MAPI::Services::Member::SecuritiesPosition::Private).to receive(:format_securities).with(securities, :current).and_return([])
          managed_securities
        end
        it 'returns an array of the formatted securities as the `securities` value' do
          formatted_securities = MAPI::Services::Member::SecuritiesPosition::Private.format_securities(securities, :current).each do |security|
            managed_security_fields.each do |field|
              security[field] = nil
            end
          end
          expect(managed_securities[:securities]).to eq(formatted_securities)
        end
        # TODO: Replace these tests with something more appropriate once we really have eligibility, authorized_by, and borrowing_capacity
        managed_security_fields.each do |key|
          it "returns an array of securities in the `securities` value that each include the #{key} key" do
            managed_securities[:securities].each do |security|
              expect(security.keys).to include(key)
            end
          end
        end
      end
    end
  end
end
