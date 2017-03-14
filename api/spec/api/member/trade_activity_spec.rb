require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do
  describe 'the TradeActivity module' do
    let(:trade_activity_module) { MAPI::Services::Member::TradeActivity }

    describe 'Trade Activity' do
      describe 'the `active_advances` MAPI endpoint' do
        let(:call_endpoint) { get "/member/#{member_id}/active_advances" }
        let(:active_advances) { double('advances', to_json: nil) }

        before do
          allow(MAPI::Services::Member::TradeActivity).to receive(:trade_activity).and_return(active_advances)
        end

        it 'calls `MAPI::Services::Member::TradeActivity.trade_activity` with the member_id and `ADVANCE`' do
          expect(MAPI::Services::Member::TradeActivity).to receive(:trade_activity).with(anything, member_id.to_s, 'ADVANCE')
          call_endpoint
        end
        it 'returns the results as JSON' do
          expect(active_advances).to receive(:to_json)
          call_endpoint
        end
        it 'returns a 503 if there is a Savon error' do
          allow(MAPI::Services::Member::TradeActivity).to receive(:trade_activity).and_raise(Savon::Error)
          call_endpoint
          expect(last_response.status).to eq(503)
        end
      end

      let(:ods_deal_structure_code) { double('ods_deal_structure_code') }
      let(:call_method) { MAPI::Services::Member::TradeActivity.trade_activity(subject, member_id, 'ADVANCE') }
      it 'should return expected advances detail hash where value could not be nil' do
        call_method.each do |row|
          expect(row['trade_date']).to be_kind_of(String)
          expect(row['funding_date']).to be_kind_of(String)
          expect(row['maturity_date']).to be_kind_of(String)
          expect(row['advance_number']).to be_kind_of(String)
          expect(row['advance_type']).to be_kind_of(String)
          expect(row['status']).to be_kind_of(String)
          expect(row['interest_rate']).to be_kind_of(Numeric)
          expect(row['current_par']).to be_kind_of(Numeric)
        end
      end
      describe 'in the production environment' do
        before do
          allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        end
        it 'returns active advances', vcr: {cassette_name: 'trade_activity_service'} do
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_large_member).and_return(false)
          allow(MAPI::Services::Member::TradeActivity).to receive(:get_ods_deal_structure_code).and_return(ods_deal_structure_code)
          call_method.each do |row|
            expect(row['trade_date']).to be_kind_of(String)
            expect(row['funding_date']).to be_kind_of(String)
            expect(row['maturity_date']).to be_kind_of(String)
            expect(row['advance_number']).to be_kind_of(String)
            expect(row['advance_type']).to eq(ods_deal_structure_code)
            expect(row['status']).to be_kind_of(String)
            expect(row['interest_rate']).to be_kind_of(Numeric)
            expect(row['current_par']).to be_kind_of(Numeric)
            expect(row['advance_confirmation']).to be_kind_of(Array)
          end
        end
        it 'returns active advances for large members', vcr: {cassette_name: 'trade_activity_service', :allow_playback_repeats => true} do
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_large_member).and_return(true)
          allow(MAPI::Services::Member::TradeActivity).to receive(:get_ods_deal_structure_code).and_return(ods_deal_structure_code)
          call_method.each do |row|
            expect(row['trade_date']).to be_kind_of(String)
            expect(row['funding_date']).to be_kind_of(String)
            expect(row['maturity_date']).to be_kind_of(String)
            expect(row['advance_number']).to be_kind_of(String)
            expect(row['advance_type']).to eq(ods_deal_structure_code)
            expect(row['status']).to be_kind_of(String)
            expect(row['interest_rate']).to be_kind_of(Numeric)
            expect(row['current_par']).to be_kind_of(Numeric)
            expect(row['advance_confirmation']).to be_kind_of(Array)
          end
        end
        it 'should call `get_trade_activity_trades` only 1 time for small members', vcr: {cassette_name: 'trade_activity_service'} do
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_large_member).and_return(false)
          allow(MAPI::Services::Member::TradeActivity).to receive(:get_ods_deal_structure_code).and_return(ods_deal_structure_code)
          expect(MAPI::Services::Member::TradeActivity).to receive(:get_trade_activity_trades).once
          MAPI::Services::Member::TradeActivity.trade_activity(subject, member_id, 'ADVANCE')
        end
        it 'should call `get_trade_activity_trades` for all trade types in `ACTIVE_ADVANCES_ARRAY` array for large members', vcr: {cassette_name: 'trade_activity_service'} do
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_large_member).and_return(true)
          expect(MAPI::Services::Member::TradeActivity).to receive(:get_trade_activity_trades).exactly(MAPI::Services::Member::TradeActivity::ACTIVE_ADVANCES_ARRAY.count).times
          MAPI::Services::Member::TradeActivity.trade_activity(subject, member_id, 'ADVANCE')
        end
        it 'should return Internal Service Error, if trade service is unavailable', vcr: {cassette_name: 'trade_activity_service_unavailable'} do
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_large_member).and_return(false)
          expect{call_method}.to raise_error(Savon::HTTPError)
        end
        it 'should return Internal Service Error, if trade service is unavailable for large members', vcr: {cassette_name: 'trade_activity_service_unavailable'} do
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_large_member).and_return(true)
          expect{call_method}.to raise_error(Savon::HTTPError)
        end
      end
      %w(development test production).each do |env|
        it "transforms the rate in #{env}", vcr: {cassette_name: 'trade_activity_service'} do
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_large_member).and_return(false)
          allow(MAPI::Services::Member::TradeActivity).to receive(:get_ods_deal_structure_code).and_return(ods_deal_structure_code)
          allow(MAPI::ServiceApp).to receive(:environment).and_return(env.to_sym)
          transformed_rate = double('A Tranformed Rate')
          allow(MAPI::Services::Member::TradeActivity).to receive(:decimal_to_percentage_rate).and_return(transformed_rate)
          advances = call_method
          expect(advances.count).to be > 0
          advances.each do |advance|
            expect(advance['interest_rate']).to be(transformed_rate)
          end
        end
        it "sorts the results in #{env}" do
          sorted_results = double('Sorted Results')
          allow(MAPI::Services::Member::TradeActivity).to receive(:sort_trades).and_return(sorted_results)
          expect(call_method).to be(sorted_results)
        end
        it 'calls the `advance_confirmation` method' do
          expect(MAPI::Services::Member::TradeActivity).to receive(:advance_confirmation).and_call_original
          call_method
        end
      end
      it 'adds the `advance_confirmation` to the appropriate advance, based on `advance_number`' do
        advance_number = rand(1000.99999)
        advance = {
          trade_date: Time.zone.today,
          advance_number: advance_number,
          interest_rate: rand()
        }
        confirmation = double('advance confirmation')
        allow(confirmation).to receive(:[]).with(:advance_number).and_return(advance_number)
        allow(JSON).to receive(:parse).and_return([advance])
        allow(MAPI::Services::Member::TradeActivity).to receive(:advance_confirmation).and_return([confirmation])
        expect(call_method.first[:advance_confirmation].first).to eq(confirmation)
      end
    end

    describe 'the `get_trade_activity_trades` method' do
      describe 'in the production environment', vcr: {cassette_name: 'trade_activity_service'} do
        let(:message) {
          {
            'v11:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}],
            'v1:tradeRequestParameters' => [{
              'v1:status' => 'VERIFIED',
              'v1:arrayOfCustomers' => [{'v1:fhlbId' => 750}],
              'v1:arrayOfAssetClasses' => [{'v1:assetClass' => 'ADVANCE'}]
            }]
          }
        }
        let(:app){ double('app', logger: double('logger'), settings: double( 'settings', environment: :production ) ) }
        let(:advances) { MAPI::Services::Member::TradeActivity.get_trade_activity_trades(app, message) }
        let(:ods_deal_structure_code) { double('ods_deal_structure_code') }
        before do
          allow(MAPI::Services::Member::TradeActivity).to receive(:get_ods_deal_structure_code).and_return(ods_deal_structure_code)
        end
        it 'should return active advances' do
          expect(advances[0]['trade_date']).to eq('2011-05-05T13:15:00.000-07:00')
          expect(advances[0]['funding_date']).to eq('2011-05-06-07:00')
          expect(advances[0]['maturity_date']).to eq('2016-05-06-07:00')
          expect(advances[0]['advance_number']).to eq('188367')
          expect(advances[0]['advance_type']).to eq(ods_deal_structure_code)
          expect(advances[0]['status']).to eq('Outstanding')
          expect(advances[0]['interest_rate']).to eq('0.022')
          expect(advances[0]['current_par']).to eq(2500000.0)
        end
        it 'calls `build_trade_datetime` to calculate the `trade_date`' do
          trade_datetime = double('A Trade DateTime')
          allow(MAPI::Services::Member::TradeActivity).to receive(:build_trade_datetime).and_return(trade_datetime)
          expect(advances.count).to be > 0
          advances.each do |advance|
            expect(advance['trade_date']).to be(trade_datetime)
          end
        end
      end
    end

    describe 'the `get_ods_deal_structure_code` method' do
      [:test, :development].each do |env|
        describe 'in the development environment' do
          let(:app) { double('app', logger: double('logger'), settings: double( 'settings', environment: env ) ) }
          let(:sub_product) { double('sub_product')}
          let(:collateral) { double('collateral', gsub: double('fixed_collateral'))}
          let(:ods_deal_structure_code) { MAPI::Services::Member::TradeActivity.get_ods_deal_structure_code(app, sub_product, collateral) }
          it 'return sub product' do
            expect(ods_deal_structure_code).to eq(sub_product)
          end
        end
      end
      describe 'in the production environment' do
        let(:app) { double('app', logger: double('logger', error: nil), settings: double( 'settings', environment: :production ) ) }
        let(:sub_product) { double('sub_product')}
        let(:collateral) { double('collateral', gsub: double('fixed_collateral'))}
        let(:ods_deal_structure_code) { MAPI::Services::Member::TradeActivity.get_ods_deal_structure_code(app, sub_product, collateral) }
        let(:empty_result_set) {double('Oracle Result Set', fetch_hash: nil)}
        let(:ods_code) {double('ods_code')}
        it 'return nil if there are no records found' do
          allow(ActiveRecord::Base.connection).to receive(:execute).and_return(empty_result_set)
          expect(ods_deal_structure_code).to eq(nil)
        end
        it 'return ods deal structure code if sub product and collateral match a record' do
          allow(MAPI::Services::Member::TradeActivity).to receive(:fetch_hash).with(app.logger, kind_of(String)).and_return({'SYS_ADVANCE_TYPE' => ods_code})
          expect(ods_deal_structure_code).to be(ods_code)
        end
        it 'removes spaces and hyphens from collateral' do
          expect(collateral).to receive(:gsub).with(/[ -]/, '')
          ods_deal_structure_code
        end
        {
          'FOO BAR' => 'FOOBAR',
          'FOO-CAR' => 'FOOCAR',
          'CATCAR' => 'CATCAR',
          'FOO- WAR' => 'FOOWAR'
        }.each do |original, result|
          it "converts a collateral type of `#{original}` to `#{result}`" do
            allow(ActiveRecord::Base.connection).to receive(:quote)
            expect(ActiveRecord::Base.connection).to receive(:quote).with(result)
            MAPI::Services::Member::TradeActivity.get_ods_deal_structure_code(app, sub_product, original)
          end
        end
        describe 'query construction' do
          before do
            allow(ActiveRecord::Base.connection).to receive(:quote)
          end

          it 'queries for the subproduct' do
            sub_product_string = SecureRandom.hex
            allow(ActiveRecord::Base.connection).to receive(:quote).with(sub_product).and_return(sub_product_string)
            expect(MAPI::Services::Member::TradeActivity).to receive(:fetch_hash).with(app.logger, kind_of(String)) do |*args, &block|
              expect(args.last).to include(sub_product_string)
              nil
            end
            ods_deal_structure_code
          end

          it 'queries for the collateral type' do
            collateral_type_string = SecureRandom.hex
            allow(ActiveRecord::Base.connection).to receive(:quote).with(collateral.gsub).and_return(collateral_type_string)
            expect(MAPI::Services::Member::TradeActivity).to receive(:fetch_hash).with(app.logger, kind_of(String)) do |*args, &block|
              expect(args.last).to include(collateral_type_string)
              nil
            end
            ods_deal_structure_code
          end
        end
      end
    end

    describe 'the `is_large_member` method' do
      describe 'in the development environment' do
        let(:is_large_member) { MAPI::Services::Member::TradeActivity.is_large_member(:development, 750) }
        it 'should return false' do
          expect(is_large_member).to eq(false)
        end
      end
      describe 'in the production environment' do
        let(:is_large_member) { MAPI::Services::Member::TradeActivity.is_large_member(:production, 750) }
        it 'should return false if there are no records found' do
          allow(ActiveRecord::Base.connection).to receive(:execute).and_return(double('Results', fetch: nil))
          expect(is_large_member).to eq(false)
        end
        it 'should return false if the number of records is less than 300' do
          allow(ActiveRecord::Base.connection).to receive(:execute).and_return(double('Results', fetch: [100]))
          expect(is_large_member).to eq(false)
        end
        it 'should return true if the number of records is greater than 300' do
          allow(ActiveRecord::Base.connection).to receive(:execute).and_return(double('Results', fetch: [400]))
          expect(is_large_member).to eq(true)
        end
      end
    end

    describe '`sort_trades` class method' do
      let(:trades) do
        trades = []
        20.times do
          trades << {'trade_date' => (Time.zone.now - rand(0..60).minutes).iso8601, 'advance_number' => rand(100000..999999) }
          trades << {'trade_date' => (Time.zone.now - rand(0..3).days).iso8601, 'advance_number' => rand(100000..999999) }
        end
        trades
      end
      let(:call_method) { MAPI::Services::Member::TradeActivity.sort_trades(trades) }
      it 'sorts the trades by `trade_date` DESC' do
        last_trade = nil
        call_method.each do |trade|
          expect(trade['trade_date'] <= last_trade['trade_date']) if last_trade
          last_trade = trade
        end
      end
      it 'sorts trades on the same `trade_date` by `advance_number` DESC' do
        5.times do
          trades[10..20].sample['trade_date'] = trades[0..10].sample['trade_date']
        end
        last_trade = nil
        call_method.each do |trade|
          expect(trade['advance_number'] <= last_trade['advance_number']) if last_trade && trade['trade_date'] == last_trade['trade_date']
          last_trade = trade
        end
      end
    end

    describe '`is_new_web_advance?` class method' do
      let(:trade) { double('A Trade XML Fragment') }
      let(:trade_status) { double('Trade Status XML Fragment', content: MAPI::Services::Member::TradeActivity::TODAYS_ADVANCES_ARRAY.sample) }
      let(:call_method) { MAPI::Services::Member::TradeActivity.is_new_web_advance?(trade) }
      let(:web_trader) { double('Trader XML Fragment', content: double('A Web Trader')) }
      before do
        allow(trade).to receive(:at_css).with('tradeHeader status').and_return(trade_status)
        allow(trade).to receive(:at_css).with('tradeHeader party trader').and_return(web_trader)
        allow(ENV).to receive(:[]).with('MAPI_WEB_AO_ACCOUNT').and_return(web_trader.content)
      end
      it 'returns false if the advance status is not a new advance' do
        allow(trade).to receive(:at_css).with('tradeHeader status').and_return(double('Trade Status XML Fragment', content: 'foo'))
        expect(call_method).to be(false)
      end
      it 'returns false if the trade was not made on the web' do
        allow(trade).to receive(:at_css).with('tradeHeader party trader').and_return(double('Trader XML Fragment', content: 'foo'))
        expect(call_method).to be(false)
      end
      %w(VERIFIED OPS_REVIEW OPS_VERIFIED SEC_REVIEWED SEC_REVIEW COLLATERAL_AUTH AUTH_TERM PEND_TERM).each do |status|
        it "returns true is the trade was made on the web and is of status `#{status}`" do
          allow(trade_status).to receive(:content).and_return(status)
          expect(call_method).to be(true)
        end
      end
    end

    describe '`build_trade_datetime` class method' do
      let(:trade) { double('Savon XML Trade Fragment', at_css: double('An XML Node', content: nil)) }
      let(:trade_date) { double('Savon XML Trade Date', content: '2015-05-07-07:00') }
      let(:trade_time) { double('Savon XML Trade Time', content: '09:55:00.100-07:00') }
      let(:call_method) { MAPI::Services::Member::TradeActivity.build_trade_datetime(trade) }

      it 'collects the `tradeDate`' do
        expect(trade).to receive(:at_css).with('tradeHeader tradeDate').and_return(trade_date)
        call_method
      end
      it 'collects the `tradeTime`' do
        expect(trade).to receive(:at_css).with('tradeHeader tradeTime').and_return(trade_date)
        call_method
      end
      it 'combines the date and time into an iso8601 string' do
        allow(trade).to receive(:at_css).with('tradeHeader tradeDate').and_return(trade_date)
        allow(trade).to receive(:at_css).with('tradeHeader tradeTime').and_return(trade_time)
        expect(call_method).to eq(trade_date.content[0..-7] + 'T' + trade_time.content)
      end
    end

    describe 'the `current_daily_total` method' do
      describe 'in the production environment' do
        let(:included_trade_1) { double('included trade 1', at_css: nil) }
        let(:included_trade_2) { double('included trade 2', at_css: nil) }
        let(:excluded_trade) { double('verified trade', at_css: nil) }
        let(:fhlbsfresponse) { [included_trade_1, included_trade_2, excluded_trade] }
        let(:savon_response) { double('savon response', doc: double('doc', remove_namespaces!: nil, xpath: fhlbsfresponse)) }
        let(:trade_connection) { double('trade_connection', call: savon_response) }
        let(:current_daily_total) { MAPI::Services::Member::TradeActivity.current_daily_total(:production, 'ADVANCE') }
        before do
          allow(MAPI::Services::Member::TradeActivity).to receive(:init_trade_connection).and_return(trade_connection)
        end
        it 'adds the daily advance activity for all members if a trade is a new web trade' do
          trade_1_amount = rand(1000..999999) + rand()
          trade_2_amount = rand(1000..999999)  + rand()
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_new_web_advance?).with(included_trade_1).and_return(true)
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_new_web_advance?).with(included_trade_2).and_return(true)
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_new_web_advance?).with(excluded_trade).and_return(false)
          allow(included_trade_1).to receive(:at_css).with('advance par amount').and_return(double('xml node', content: trade_1_amount))
          allow(included_trade_2).to receive(:at_css).with('advance par amount').and_return(double('xml node', content: trade_2_amount))
          expect(current_daily_total).to eq(trade_1_amount + trade_2_amount)
        end
        it 'raises an error if a Savon connection cannot be established' do
          allow(trade_connection).to receive(:call).and_raise(Savon::Error)
          expect{current_daily_total}.to raise_error(Savon::Error)
        end
        it 'calls the trade service with a message limiting the tradeDate to today' do
          today = Time.zone.today
          allow(Time.zone).to receive(:today).and_return(today)
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_new_web_advance?)
          expected_message = include('v1:tradeRequestParameters' => include(include(
            {'v1:rangeOfTradeDates' => {'v1:startDate' => today.iso8601, 'v1:endDate' => today.iso8601}}
          )))
          expect(trade_connection).to receive(:call).with(anything, include(message: expected_message))
          current_daily_total
        end
      end
      [:development, :test].each do |env|
        describe "in the #{env} environment" do
          let(:current_daily_total) { MAPI::Services::Member::TradeActivity.current_daily_total(env, 'ADVANCE') }
          before { allow(MAPI::Services::Member::TradeActivity).to receive(:init_trade_connection).and_return(false) }

          it 'returns a randomly-generated float' do
            expect(current_daily_total).to be_kind_of(Float)
          end
        end
      end
    end

    describe 'Todays Trade Activity' do
      let(:todays_advances) { MAPI::Services::Member::TradeActivity.todays_trade_activity(subject, member_id, 'ADVANCE') }

      before do
        allow(MAPI::Services::Member::TradeActivity).to receive(:is_new_web_advance?).and_return(true)
      end

      describe 'endpoint' do
        it 'is invoked via a member endpoint' do
          expect(MAPI::Services::Member::TradeActivity).to receive(:todays_trade_activity).with(kind_of(described_class), member_id.to_s, 'ADVANCE')
          get "/member/#{member_id}/todays_advances"
        end
        it 'has its results transformed into JSON' do
          results = double('Some Trades')
          allow(MAPI::Services::Member::TradeActivity).to receive(:todays_trade_activity).and_return(results)
          expect(results).to receive(:to_json)
          get "/member/#{member_id}/todays_advances"
        end
      end

      it 'should return expected today advances detail hash where value could not be nil' do
        todays_advances.each do |row|
          expect(row['trade_date']).to be_kind_of(String)
          expect(row['funding_date']).to be_kind_of(String)
          expect(row['maturity_date']).to be_kind_of(String)
          expect(row['advance_number']).to be_kind_of(String)
          expect(row['advance_type']).to be_kind_of(String)
          expect(row['status']).to be_kind_of(String)
          expect(row['interest_rate']).to be_kind_of(Numeric)
          expect(row['current_par']).to be_kind_of(Numeric)
        end
      end
      describe 'in the production environment', vcr: {cassette_name: 'trade_activity_service'} do
        let(:trade_connection) { MAPI::Services::Member::TradeActivity.init_trade_connection(:production) }
        before do
          allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        end

        it 'checks if the trades are new web trades' do
          expect(MAPI::Services::Member::TradeActivity).to receive(:is_new_web_advance?).at_least(:once)
          todays_advances
        end

        it 'should return active advances' do
          todays_advances.each do |row|
            expect(row['trade_date']).to be_kind_of(String)
            expect(row['funding_date']).to be_kind_of(String)
            expect(row['maturity_date']).to be_kind_of(String)
            expect(row['advance_number']).to be_kind_of(String)
            expect(row['advance_type']).to be_kind_of(String)
            expect(row['status']).to be_kind_of(String)
            expect(row['interest_rate']).to be_kind_of(Numeric)
            expect(row['current_par']).to be_kind_of(Numeric)
          end
        end
        it 'should return Internal Service Error, if trade service is unavailable', vcr: {cassette_name: 'trade_activity_service_unavailable'} do
          get "/member/#{member_id}/todays_advances"
          expect(last_response.status).to eq(503)
        end
        it 'calls `build_trade_datetime` to calculate the `trade_date`' do
          trade_datetime = double('A Trade DateTime')
          allow(MAPI::Services::Member::TradeActivity).to receive(:build_trade_datetime).and_return(trade_datetime)
          expect(todays_advances.count).to be > 0
          todays_advances.each do |advance|
            expect(advance['trade_date']).to be(trade_datetime)
          end
        end

        it 'calls the trade service with a message limiting the tradeDate to today' do
          today = Time.zone.today
          allow(Time.zone).to receive(:today).and_return(today)
          allow(MAPI::Services::Member::TradeActivity).to receive(:is_new_web_advance?)
          expected_message = include('v1:tradeRequestParameters' => include(include(
            {'v1:rangeOfTradeDates' => {'v1:startDate' => today.iso8601, 'v1:endDate' => today.iso8601}}
          )))
          expect(trade_connection).to receive(:call).with(anything, include(message: expected_message)).and_call_original
          todays_advances
        end
      end
      %w(development test production).each do |env|
        it "transforms the rate in #{env}", vcr: {cassette_name: 'trade_activity_service'} do
          allow(MAPI::ServiceApp).to receive(:environment).and_return(env.to_sym)
          transformed_rate = double('A Tranformed Rate')
          allow(MAPI::Services::Member::TradeActivity).to receive(:decimal_to_percentage_rate).and_return(transformed_rate)
          expect(todays_advances.count).to be > 0
          todays_advances.each do |advance|
            expect(advance['interest_rate']).to be(transformed_rate)
          end
        end
        it "sorts the results in #{env}" do
          sorted_results = double('Sorted Results')
          allow(MAPI::Services::Member::TradeActivity).to receive(:sort_trades).and_return(sorted_results)
          expect(todays_advances).to be(sorted_results)
        end
      end
    end

    describe 'Todays Credit Activity' do
      string_attributes = [['instrument_type','instrumentType'], ['status', 'status'], ['transaction_number', 'tradeID'], ['product_description', 'productDescription'], ['termination_full_partial', 'terminationFullPartial'], ['product', 'product'], ['sub_product', 'subProduct'], ['life_cycle_event', 'lifeCycleEvent'], ['lc_number', 'lcNumber'], ['beneficiary', 'beneficiary']]
      float_attributes = [['termination_par', 'terminationPar'], ['current_par', 'amount'], ['interest_rate', 'rate'], ['termination_fee', 'terminationFee']]
      date_attributes = [[['trade_date', 'tradeDate'], 'funding_date', 'fundingDate'], ['maturity_date', 'maturityDate']]

      let(:attribute) { double('attribute') }
      let(:activity) { double('activity', :[] => nil, :[]= => nil, at_css: nil) }
      let(:activity_hash) { [activity] }
      let(:non_exercised_status) { MAPI::Services::Member::TradeActivity::TODAYS_CREDIT_ARRAY - ['EXERCISED'] }
      it 'should call `MAPI::Services::Member::TradeActivity.todays_credit_activity` when the endpoint is hit' do
        expect(MAPI::Services::Member::TradeActivity).to receive(:todays_credit_activity)
        get "/member/#{member_id}/todays_credit_activity"
      end
      it 'returns an array of activity objects', vcr: {cassette_name: 'todays_credit_activity'} do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        get "/member/#{member_id}/todays_credit_activity"
        activity = JSON.parse(last_response.body).first.with_indifferent_access
        expect(activity[:transaction_number]).to eq('318614')
        expect(activity[:current_par]).to eq(10600000.to_f)
        expect(activity[:interest_rate]).to be_nil
        expect(activity[:trade_date]).to eq('2013-03-19')
        expect(activity[:funding_date]).to eq('2013-03-19')
        expect(activity[:maturity_date]).to eq('2015-09-14')
        expect(activity[:product_description]).to eq('LC LC LC')
        expect(activity[:instrument_type]).to eq('LC')
        expect(activity[:status]).to eq('VERIFIED')
        expect(activity[:termination_par]).to be_nil
        expect(activity[:termination_fee]).to be_nil
        expect(activity[:termination_full_partial]).to be_nil
        expect(activity[:termination_date]).to be_nil
        expect(activity[:product]).to eq('LC')
        expect(activity[:sub_product]).to eq('LC')
        expect(activity[:life_cycle_event]).to eq('Cancellation')
        expect(activity[:lc_number]).to eq('2016-78')
        expect(activity[:maintenance_charge]).to eq(10.0)
        expect(activity[:beneficiary]).to eq('State of California')
      end
      it 'should return Internal Service Error, if service is unavailable', vcr: {cassette_name: 'todays_credit_activity_service_unavailable'} do
        allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
        get "/member/#{member_id}/todays_credit_activity"
        expect(last_response.status).to eq(503)
      end

      %w{development test production}.each do |env|
        it "transforms the rate in #{env}", vcr: {cassette_name: 'todays_credit_activity'} do
          transformed_rate = double('A Tranformed Rate')
          allow(MAPI::Services::Member::TradeActivity).to receive(:decimal_to_percentage_rate).and_return(transformed_rate)
          advances = MAPI::Services::Member::TradeActivity.todays_credit_activity(env.to_sym, member_id)
          expect(advances.count).to be > 0
          advances.each do |advance|
            expect(advance[:interest_rate]).to be(transformed_rate)
          end
        end
      end
      %w(development test).each do |env|
        describe "in the #{env} environment" do
          let(:todays_credit_activity) { MAPI::Services::Member::TradeActivity.todays_credit_activity(env.to_sym, member_id) }
          before do
            allow(MAPI::ServiceApp).to receive(:environment).and_return(env.to_sym)
            allow(JSON).to receive(:parse).and_return(activity_hash)
          end
          MAPI::Services::Member::TradeActivity::TODAYS_CREDIT_ARRAY.each do |status|
            it "includes activites that have a status of #{status}" do
              allow(activity).to receive(:[]).with('status').and_return(status)
              expect(todays_credit_activity.length).to eq(1)
            end
          end
          it 'excludes activities with a status that is not included in the TODAYS_CREDIT_ARRAY' do
            allow(activity).to receive(:[]).with('status').and_return('foo')
            expect(todays_credit_activity.length).to eq(0)
          end
          describe 'exclusion criteria for ADVANCES' do
            before do
              allow(activity).to receive(:[]).with('status').and_return(non_exercised_status.sample)
              allow(activity).to receive(:[]).with('instrumentType').and_return('ADVANCE')
              allow(activity).to receive(:[]).with('fundingDate').and_return((Time.zone.today - 2.days).to_s)
            end
            it 'includes ADVANCEs funded before today if they have been EXERCISED' do
              allow(activity).to receive(:[]).with('status').and_return('EXERCISED')
              expect(todays_credit_activity.length).to eq(1)
            end
            it 'includes ADVANCEs funded before today if they have not been EXERCISED and have a `terminationPar' do
              allow(activity).to receive(:[]).with('terminationPar').and_return(1000)
              expect(todays_credit_activity.length).to eq(1)
            end
            it 'excludes ADVANCEs funded before today if they have not been EXERCISED and do not have a `terminationPar' do
              expect(todays_credit_activity.length).to eq(0)
            end
          end
          string_attributes.each do |string_attribute|
            it "formats the `#{string_attribute.first}` as a string" do
              expect(attribute).to receive(:to_s)
              allow(activity).to receive(:[]).with(string_attribute.last).and_return(attribute)
              todays_credit_activity
            end
          end
          float_attributes.each do |float_attribute|
            it "formats the `#{float_attribute.first}` as a float" do
              expect(attribute).to receive(:to_f)
              allow(activity).to receive(:[]).with(float_attribute.last).and_return(attribute)
              todays_credit_activity
            end
          end
          date_attributes.each do |date_attribute|
            it "formats the `#{date_attribute.first}` as a date" do
              allow(attribute).to receive(:[]=).and_return(attribute)
              expect(Time.zone).to receive(:parse).with(attribute).and_return(double('time object', :to_date => nil))
              allow(activity).to receive(:[]).with(date_attribute.last).and_return(attribute)
              todays_credit_activity
            end
          end
          it 'parses the `terminationDate` into a Date' do
            allow(activity).to receive(:[]).with('terminationDate').and_return(attribute)
            expect(DateTime).to receive(:strptime).with(attribute, '%m/%d/%Y').and_return(double(DateTime, to_date: nil))
            todays_credit_activity
          end
          it 'parses the `maintenance_charge` into a float' do
            allow(activity).to receive(:[]).with('maintenanceFee').and_return(attribute)
            expect(attribute).to receive(:to_f).and_return(0.0)
            todays_credit_activity
          end
          it 'multiples the `maintenance_charge` by 10000' do
            original_charge = rand
            allow(activity).to receive(:[]).with('status').and_return(MAPI::Services::Member::TradeActivity::TODAYS_CREDIT_ARRAY.first)
            allow(activity).to receive(:[]).with('maintenanceFee').and_return(attribute)
            allow(attribute).to receive(:to_f).and_return(original_charge)
            expect(todays_credit_activity.length).to be > 0
            todays_credit_activity.each do |activity|
              expect(activity[:maintenance_charge]).to eq(original_charge * 10000)
            end
          end
          it 'includes the parsed terminationDate in the activity response' do
            value = double(Date)
            allow(activity).to receive(:[]).with('status').and_return(MAPI::Services::Member::TradeActivity::TODAYS_CREDIT_ARRAY.first)
            allow(activity).to receive(:[]).with('terminationDate').and_return(attribute)
            allow(DateTime).to receive(:strptime).with(attribute, anything).and_return(double(DateTime, to_date: value))
            expect(todays_credit_activity.first[:termination_date]).to be(value)
          end
        end
      end

      describe 'in the production environment', vcr: {cassette_name: 'todays_credit_activity'} do
        let(:savon_response) { double('savon response', doc: double('doc', remove_namespaces!: nil, xpath: activity_hash)) }
        let(:trade_activity_connection) { double('trade_connection', call: savon_response) }
        let(:todays_credit_activity) { MAPI::Services::Member::TradeActivity.todays_credit_activity(:production, member_id) }
        it 'initiates a Savon client connection' do
          expect(Savon).to receive(:client)
          todays_credit_activity
        end

        describe 'with the trade_activity_connection stubbed' do
          before do
            allow(MAPI::Services::Member::TradeActivity).to receive(:init_trade_activity_connection).and_return(trade_activity_connection)
          end
          it 'calls `trade_activity_connection` with :get_trade_activity' do
            expect(trade_activity_connection).to receive(:call).with(:get_trade_activity, anything)
            todays_credit_activity
          end
          it 'calls `trade_activity_connection` with a message tag of \'tradeRequest\'' do
            expect(trade_activity_connection).to receive(:call).with(anything, hash_including(message_tag: 'tradeRequest'))
            todays_credit_activity
          end
          MAPI::Services::Member::TradeActivity::TODAYS_CREDIT_ARRAY.each do |status|
            it "includes activites that have a status of #{status}" do
              allow(activity).to receive(:at_css).with('status').and_return(double('xml node', content: status))
              expect(todays_credit_activity.length).to eq(1)
            end
          end
          it 'excludes activities with a status that is not included in the TODAYS_CREDIT_ARRAY' do
            allow(activity).to receive(:at_css).with('status').and_return(double('xml node', content: 'foo'))
            expect(todays_credit_activity.length).to eq(0)
          end
          describe 'exclusion criteria for ADVANCES' do
            before do
              allow(activity).to receive(:at_css).with('status').and_return(double('xml node', content: non_exercised_status.sample))
              allow(activity).to receive(:at_css).with('instrumentType').and_return(double('xml node', content: 'ADVANCE'))
              allow(activity).to receive(:at_css).with('fundingDate').and_return(double('xml node', content: (Time.zone.today - 2.days).to_s))
            end
            it 'includes ADVANCEs funded before today if they have been EXERCISED' do
              allow(activity).to receive(:at_css).with('status').and_return(double('xml node', content: 'EXERCISED'))
              expect(todays_credit_activity.length).to eq(1)
            end
            it 'includes ADVANCEs funded before today if they have not been EXERCISED and have a `terminationPar' do
              allow(activity).to receive(:at_css).with('terminationPar').and_return(double('xml node', content: 1000))
              expect(todays_credit_activity.length).to eq(1)
            end
            it 'excludes ADVANCEs funded before today if they have not been EXERCISED and do not have a `terminationPar' do
              expect(todays_credit_activity.length).to eq(0)
            end
          end
          string_attributes.each do |string_attribute|
            it "formats the `#{string_attribute.first}` as a string" do
              expect(attribute).to receive(:to_s)
              allow(activity).to receive(:at_css).with(string_attribute.last).and_return(double('xml node', content: attribute))
              todays_credit_activity
            end
          end
          float_attributes.each do |float_attribute|
            it "formats the `#{float_attribute.first}` as a float" do
              expect(attribute).to receive(:to_f)
              allow(activity).to receive(:at_css).with(float_attribute.last).and_return(double('xml node', content: attribute))
              todays_credit_activity
            end
          end
          date_attributes.each do |date_attribute|
            it "formats the `#{date_attribute.first}` as a date" do
              expect(Time.zone).to receive(:parse).with(attribute).and_return(double('time object', :to_date => nil))
              allow(activity).to receive(:at_css).with(date_attribute.last).and_return(double('xml node', content: attribute))
              todays_credit_activity
            end
          end
          it 'parses the `terminationDate` into a Date' do
            allow(activity).to receive(:at_css).with('terminationDate').and_return(double('xml node', content: attribute))
            expect(DateTime).to receive(:strptime).with(attribute, '%m/%d/%Y').and_return(double(DateTime, to_date: nil))
            todays_credit_activity
          end
          it 'includes the parsed terminationDate in the activity response' do
            value = double(Date)
            allow(activity).to receive(:at_css).with('status').and_return(double('xml node', content: MAPI::Services::Member::TradeActivity::TODAYS_CREDIT_ARRAY.first))
            allow(activity).to receive(:at_css).with('terminationDate').and_return(double('xml node', content: attribute))
            allow(DateTime).to receive(:strptime).with(attribute, anything).and_return(double(DateTime, to_date: value))
            expect(todays_credit_activity.first[:termination_date]).to be(value)
          end
        end
      end
    end

    describe '`historic_advances_query` class method' do
      let(:limit) { double('A Limit') }
      let(:after_date) { instance_double(Date) }
      let(:member_id) { double('Member ID') }
      let(:quoted_value) { SecureRandom.hex }
      let(:call_method) { MAPI::Services::Member::TradeActivity.historic_advances_query(member_id, after_date, limit) }

      before do
        allow(MAPI::Services::Member::TradeActivity).to receive(:quote).and_call_original
      end

      it 'returns a SELECT statement' do
        expect(call_method).to match(/\A\s*SELECT.*\s+FROM\s+ODS\.DEAL@ODS_LK\s+WHERE\s+.*\s+ORDER\s+BY\s+TRADE_DATE DESC\s*\z/mi)
      end
      it 'includes the quoted `limit` in the statement' do
        allow(MAPI::Services::Member::TradeActivity).to receive(:quote).with(limit).and_return(quoted_value)
        expect(call_method).to match /\sAND\s+ROWNUM\s+<=\s+#{quoted_value}\s/mi
      end
      it 'includes the quoted `member_id` in the statement' do
        allow(MAPI::Services::Member::TradeActivity).to receive(:quote).with(member_id).and_return(quoted_value)
        expect(call_method).to match /\sAND\s+FHLB_ID\s+=\s+#{quoted_value}\s/mi
      end
      it 'includes the quoted `after_date` in the statement' do
        allow(MAPI::Services::Member::TradeActivity).to receive(:quote).with(after_date).and_return(quoted_value)
        expect(call_method).to match /\sAND\s+NVL\(TERMINATION_DATE,\s+MATURITY_DATE\)\s+>=\s+#{quoted_value}\s/mi
      end
      it 'defaults the limit to `2000` if not provided' do
        expect(MAPI::Services::Member::TradeActivity).to receive(:quote).with(2000)
        MAPI::Services::Member::TradeActivity.historic_advances_query(member_id, after_date)
      end
    end

    describe '`historic_advances_fetch` class method' do
      let(:member_id) { double('Member ID') }
      let(:app_instance) { instance_double(app, logger: instance_double(Logger))}
      let(:entries) { instance_double(Array) }
      let(:call_method) { MAPI::Services::Member::TradeActivity.historic_advances_fetch(app_instance, member_id, after_date) }

      describe 'when not faking' do
        let(:after_date) { instance_double(Date) }
        let(:sql) { double('An SQL Query') }
        before do
          allow(MAPI::Services::Member::TradeActivity).to receive(:should_fake?).with(app_instance).and_return(false)
          allow(MAPI::Services::Member::TradeActivity).to receive(:historic_advances_query).with(member_id, after_date).and_return(sql)
          allow(MAPI::Services::Member::TradeActivity).to receive(:fetch_hashes).and_return(entries)
        end
        it 'calls `historic_advances_query` with the `after_date` and `member_id`' do
          expect(MAPI::Services::Member::TradeActivity).to receive(:historic_advances_query).with(member_id, after_date)
          call_method
        end
        it 'calls `fetch_hashes` with the built SQL' do
          expect(MAPI::Services::Member::TradeActivity).to receive(:fetch_hashes).with(app_instance.logger, sql)
          call_method
        end
        it 'returns the result of the fetch' do
          expect(call_method).to be(entries)
        end
      end

      describe 'when faking' do
        let(:after_date) { Time.zone.today }
        let(:member_id_str) { member_id.to_i.to_s }
        let(:rng) { Random.new }
        before do
          allow(MAPI::Services::Member::TradeActivity).to receive(:should_fake?).with(app_instance).and_return(true)
          allow(member_id).to receive(:to_i).and_return(rand(1..100))
          allow(Random).to receive(:new).and_return(rng)
        end
        it 'constructs a random number generator based on the `member_id` as the leading digits of the seed' do
          expect(Random).to receive(:new).with(digits_in_range(member_id.to_i, 0..(member_id_str.length - 1))).and_call_original
          call_method
        end
        it 'constructs a random number generator based on the `after_date` as the trailing digits of the seed' do
          expect(Random).to receive(:new).with(digits_in_range(after_date.to_time.to_i, member_id_str.length..-1)).and_call_original
          call_method
        end
        it 'does not call `Kernel.rand`' do
          expect(Kernel).to_not receive(:rand)
          call_method
        end
        it 'does call rand on the seeded RNG' do
          expect(rng).to receive(:rand).at_least(:once).and_call_original
          call_method
        end
        it 'builds some entries' do
          expect(call_method).to include(hash_including('TRADE_DATE', 'FUNDING_DATE', 'MATURITY_DATE', 'ADVANCE_NUMBER', 'ORIGINAL_PAR', 'ADVANCE_TYPE'))
        end
        it 'builds the same entries each time' do
          expect(call_method).to match(call_method)
        end
        it 'builds entries with a `TRADE_DATE` that is before the `FUNDING_DATE`' do
          entry = call_method.first
          expect(entry['TRADE_DATE']).to be < entry['FUNDING_DATE']
        end
        it 'builds entries with a `FUNDING_DATE` that is before the `MATURITY_DATE`' do
          entry = call_method.first
          expect(entry['FUNDING_DATE']).to be < entry['MATURITY_DATE']
        end
      end
    end

    describe '`historic_advances` class method' do
      let(:member_id) { double('Member ID') }
      let(:after_date) { instance_double(Date) }
      let(:app_instance) { instance_double(app, logger: instance_double(Logger))}
      let(:call_method) { MAPI::Services::Member::TradeActivity.historic_advances(app_instance, member_id, after_date) }

      it 'calls `historic_advances_fetch` with the `member_id`' do
        expect(MAPI::Services::Member::TradeActivity).to receive(:historic_advances_fetch).with(anything, member_id, anything)
        call_method
      end
      it 'calls `historic_advances_fetch` with the app instance' do
        expect(MAPI::Services::Member::TradeActivity).to receive(:historic_advances_fetch).with(app_instance, anything, anything)
        call_method
      end
      it 'calls `historic_advances_fetch` with the `after_date`' do
        expect(MAPI::Services::Member::TradeActivity).to receive(:historic_advances_fetch).with(anything, anything, after_date)
        call_method
      end
      it 'defaults the `after_date` to 18 months ago if not provided' do
        today = Time.zone.today
        allow(Time.zone).to receive(:today).and_return(today)
        expect(MAPI::Services::Member::TradeActivity).to receive(:historic_advances_fetch).with(anything, anything, match(Time.zone.today - 18.months))
        MAPI::Services::Member::TradeActivity.historic_advances(app_instance, member_id)
      end
      describe 'processing entries' do
        let(:maturity_date) { instance_double(String) }
        let(:funding_date) { instance_double(String) }
        let(:trade_date) { instance_double(String) }
        let(:original_par) { instance_double(String) }
        let(:advance_type) { instance_double(String) }
        let(:advance_number) { instance_double(String) }
        let(:matching_confirmation) {
          {
            advance_number: advance_number
          }
        }
        let(:confirmations) {
          [
            {
              advance_number: double(String)
            },
            matching_confirmation,
            {
              advance_number: double(String)
            }
          ]
        }
        let(:raw_entries) { [
          {
            'MATURITY_DATE' => maturity_date,
            'FUNDING_DATE' => funding_date,
            'TRADE_DATE' => trade_date,
            'ORIGINAL_PAR' => original_par,
            'ADVANCE_TYPE' => advance_type,
            'ADVANCE_NUMBER' => advance_number
          }
        ] }
        before do
          allow(MAPI::Services::Member::TradeActivity).to receive(:historic_advances_fetch).and_return(raw_entries)
          allow(MAPI::Services::Member::TradeActivity).to receive(:advance_confirmation).and_return(confirmations)
          allow(advance_number).to receive(:to_s).and_return(advance_number)
        end

        it 'converts each entries `MATURITY_DATE` to an ISO-8601 string' do
          expect(maturity_date).to receive_message_chain(:to_date, :iso8601)
          call_method
        end
        it 'converts each entries `FUNDING_DATE` to an ISO-8601 string' do
          expect(funding_date).to receive_message_chain(:to_date, :iso8601)
          call_method
        end
        it 'converts each entries `TRADE_DATE` to an ISO-8601 string' do
          expect(trade_date).to receive_message_chain(:to_date, :iso8601)
          call_method
        end
        it 'converts each entries `ORIGINAL_PAR` to an integer' do
          expect(original_par).to receive(:to_i)
          call_method
        end
        it 'converts each entries `ADVANCE_NUMBER` to a string' do
          expect(advance_number).to receive(:to_s)
          call_method
        end
        it 'converts each entries `ADVANCE_TYPE` to a string' do
          expect(advance_type).to receive(:to_s)
          call_method
        end
        it 'returns an array of indifferent access hashes' do
          expect(call_method.first).to be_kind_of(ActiveSupport::HashWithIndifferentAccess)
        end
        it 'calls `advance_confirmation` with the app instance' do
          expect(MAPI::Services::Member::TradeActivity).to receive(:advance_confirmation).with(app_instance, anything, anything)
          call_method
        end
        it 'calls `advance_confirmation` with the `member_id`' do
          expect(MAPI::Services::Member::TradeActivity).to receive(:advance_confirmation).with(anything, member_id, anything)
          call_method
        end
        it 'calls `advance_confirmation` with the advances numbers from the entries' do
          expect(MAPI::Services::Member::TradeActivity).to receive(:advance_confirmation).with(anything, anything, include(advance_number))
          call_method
        end
        it 'populates the each entries `advance_confirmation`' do
          expect(call_method.first[:advance_confirmation]).to match([matching_confirmation])
        end
        it 'downcases the keys of the entries' do
          expect(call_method).to match([hash_including(:maturity_date, :trade_date, :funding_date, :original_par, :advance_number, :advance_type, :advance_confirmation)])
        end
      end
    end

    describe '`historic_loc_query` class method' do
      let(:member_id) { instance_double(String) }
      let(:start_date) { instance_double(Date) }
      let(:sentinel) { SecureRandom.hex }
      let(:call_method) { trade_activity_module.historic_loc_query(member_id, start_date) }

      before { allow(trade_activity_module).to receive(:quote).and_return(SecureRandom.hex) }

      it 'returns a select query' do
        expect(call_method).to match(/\A\s*select\s+distinct\s+lc.lc_transaction_number,\s+fhlb_id\s+/i)
      end
      it 'selects from `portfolios.lcs_trans` and `portfolios.lcs`' do
        expect(call_method).to match(/\s*from\s+portfolios.lcs_trans\s+lcx,\s+portfolios.lcs\s+lc\s+/i)
      end
      it 'includes the `lc_id` in the WHERE clause' do
        expect(call_method).to match(/\s*where(\s+\S+\s+=\s+\S+\s+AND)*\s+lc.lc_id\s+=\s+lcx.lc_id(\s+|\z)/)
      end
      it 'includes the `fhlb_id` in the WHERE clause' do
        allow(trade_activity_module).to receive(:quote).with(member_id).and_return(sentinel)
        expect(call_method).to match(/\swhere(\s+\S+\s+=\s+\S+\s+and)*\s+fhlb_id\s+=\s+#{sentinel}(\s+|\z)/)
      end
      it 'groups by `lc.lc_transaction_number` and `fhlb_id`' do
        expect(call_method).to match(/\s*group\s+by\s+lc.lc_transaction_number,\s+fhlb_id\s+/i)
      end
      it 'only includes locs with an update date greater than or equal to the start date' do
        allow(trade_activity_module).to receive(:quote).with(start_date).and_return(sentinel)
        expect(call_method).to match(/\s*having\s+max\(lcx.lcx_update_date\)\s+>=\s+#{sentinel}(\s+|\z)/i)
      end
    end

    describe '`historic_activities_query` class method' do
      let(:member_id) { instance_double(String) }
      let(:start_date) { instance_double(Date) }
      let(:sentinel) { SecureRandom.hex }
      let(:call_method) { trade_activity_module.historic_activities_query(member_id, start_date) }

      before { allow(trade_activity_module).to receive(:quote).and_return(SecureRandom.hex) }

      it 'returns a select query' do
        expect(call_method).to match(/\A\s*select\s+unique\s+instrument,\s+calypso_internal_ref\s+/i)
      end
      it 'selects from `ods.dEAL@ODS_LK`' do
        expect(call_method).to match(/\s*from\s+ods.dEAL@ODS_LK\s+/i)
      end
      it 'only includes activities where the LAST_UPDATE_DATETIME is less than the SYSDATE' do
        expect(call_method).to match(/\s*where(\s+\S+\s+=\s+\S+\s+and)*\s+LAST_UPDATE_DATETIME\s+<\s+SYSDATE(\s+|\z)/)
      end
      it 'only includes activities with an update date greater than or equal to the start date' do
        allow(trade_activity_module).to receive(:quote).with(start_date).and_return(sentinel)
        expect(call_method).to match(/\s*where(\s+\S+\s+<\s+\S+\s+and)*\s+LAST_UPDATE_DATETIME\s+>=\s+#{sentinel}(\s+|\z)/)
      end
      it 'includes the `fhlb_id` in the WHERE clause' do
        allow(trade_activity_module).to receive(:quote).with(member_id).and_return(sentinel)
        expect(call_method).to match(/\s*where(\s+\S+\s+<\s+\S+\s+and\s+\S+\s+>=\s+\S+\s+and)*\s+fhlb_id\s+=\s+#{sentinel}(\s+|\z)/)
      end
    end

    describe '`historic_credit_activity` class method' do
      let(:today) { Time.zone.today }
      let(:member_id) { instance_double(String, to_i: rand(1..9999)) }
      let(:start_date) { instance_double(Date) }
      let(:credit_activity) { instance_double(Hash, :[] => nil, :[]= => nil) }
      let(:call_method) { trade_activity_module.historic_credit_activity(app, member_id, start_date) }
      before do
        allow(trade_activity_module).to receive(:process_credit_activities)
        allow(JSON).to receive(:parse).and_return([credit_activity])
      end

      it 'sends the credit activities array to the `process_credit_activities` method' do
        expect(trade_activity_module).to receive(:process_credit_activities).with([credit_activity])
        call_method
      end
      it 'returns the results of calling `process_credit_activities`' do
        processed_activities = instance_double(Array)
        allow(trade_activity_module).to receive(:process_credit_activities).and_return(processed_activities)
        expect(call_method).to eq(processed_activities)
      end
      describe 'when `should_fake?` returns true' do
        let(:rng) { instance_double(Random) }
        let(:funding_date_offset) { rand(1..14) }
        let(:maturity_date_offset) { rand(0..7) }
        before do
          allow(trade_activity_module).to receive(:should_fake?).and_return(true)
          allow(Random).to receive(:new).and_return(rng)
          allow(rng).to receive(:rand).and_return(funding_date_offset, maturity_date_offset)
        end
        it 'retrieves fake credit activity by means of a JSON file' do
          expect(JSON).to receive(:parse).with(File.read(File.join(MAPI.root, 'fakes', 'credit_activity.json'))).and_return([credit_activity])
          call_method
        end
        it 'sets `fundingDate` to today minus an offset' do
          expect(credit_activity).to receive(:[]=).with('fundingDate', (today - funding_date_offset).to_s)
          call_method
        end
        it 'sets `maturityDate` to today plus an offset' do
          expect(credit_activity).to receive(:[]=).with('maturityDate', (today + maturity_date_offset).to_s)
          call_method
        end
      end
      describe 'when `should_fake?` returns false' do
        let(:attribute) { double('attribute') }
        let(:activity) { double('activity', :[] => nil, :[]= => nil, at_css: nil) }
        let(:activity_hash) { [activity] }
        let(:savon_response) { double('savon response', doc: double('doc', remove_namespaces!: nil, xpath: activity_hash)) }
        let(:trade_activity_connection) { double('trade_connection', call: savon_response) }
        let(:historic_loc_query) { instance_double(String) }
        let(:historic_activities_query) { instance_double(String) }
        let(:loc_trade_ids) { [rand(1000..99999), rand(1000..99999), rand(1000..99999)] }
        let(:other_instrument_trade_ids) { [rand(1000..99999), rand(1000..99999), rand(1000..99999)] }
        let(:loc_hash) { instance_double(Hash, :[] => nil) }
        let(:other_instrument_hash) { instance_double(Hash, :[] => nil) }
        let(:app){ double('app', logger: double('logger'), settings: double( 'settings', environment: :production ) ) }
        let(:call_method) { trade_activity_module.historic_credit_activity(app, member_id, start_date) }
        before do
          allow(trade_activity_module).to receive(:should_fake?).and_return(false)
          allow(trade_activity_module).to receive(:fetch_hashes).and_return([])
          allow(trade_activity_module).to receive(:historic_loc_query).and_return(historic_loc_query)
          allow(trade_activity_module).to receive(:historic_activities_query).and_return(historic_activities_query)
          allow(trade_activity_module).to receive(:init_trade_activity_connection).and_return(trade_activity_connection)
        end
        describe 'fetching the letter of credit trade ids' do
          it 'calls `historic_loc_query` to get the proper SQL query' do
            expect(trade_activity_module).to receive(:historic_loc_query).with(member_id, start_date).and_return(historic_loc_query)
            call_method
          end
          it 'calls `fetch_hashes` with the proper SQL' do
            expect(trade_activity_module).to receive(:fetch_hashes).with(app.logger, historic_loc_query, {}, true).and_return([])
            call_method
          end
          it 'selects only the `lc_transaction_number` from the returned hashes' do
            expect(loc_hash).to receive(:[]).with('lc_transaction_number').and_return(*loc_trade_ids)
            allow(trade_activity_module).to receive(:fetch_hashes).with(app.logger, historic_loc_query, {}, true).and_return([loc_hash, loc_hash, loc_hash])
            call_method
          end
        end
        describe 'fetching the other instrument trade ids' do
          it 'calls `historic_activities_query` to get the proper SQL query' do
            expect(trade_activity_module).to receive(:historic_activities_query).with(member_id, start_date).and_return(historic_activities_query)
            call_method
          end
          it 'calls `fetch_hashes` with the proper SQL' do
            expect(trade_activity_module).to receive(:fetch_hashes).with(app.logger, historic_activities_query, {}, true).and_return([])
            call_method
          end
          it 'selects only the `calypso_internal_ref` from the returned hashes' do
            expect(other_instrument_hash).to receive(:[]).with('calypso_internal_ref').and_return(*other_instrument_trade_ids)
            allow(trade_activity_module).to receive(:fetch_hashes).with(app.logger, historic_activities_query, {}, true).and_return([other_instrument_hash, other_instrument_hash, other_instrument_hash])
            call_method
          end
        end
        describe 'when no trade ids are found' do
          it 'does not initiate a trade activity connection' do
            expect(trade_activity_module).not_to receive(:init_trade_activity_connection)
            call_method
          end
          it 'passes an empty array to `process_credit_activities` if there are no trade ids' do
            expect(trade_activity_module).to receive(:process_credit_activities).with([])
            call_method
          end
        end
        describe 'when trade_ids are found' do
          before do
            allow(loc_hash).to receive(:[]).with('lc_transaction_number').and_return(*loc_trade_ids)
            allow(trade_activity_module).to receive(:fetch_hashes).with(app.logger, historic_loc_query, {}, true).and_return([loc_hash, loc_hash, loc_hash])
            allow(other_instrument_hash).to receive(:[]).with('calypso_internal_ref').and_return(*other_instrument_trade_ids)
            allow(trade_activity_module).to receive(:fetch_hashes).with(app.logger, historic_activities_query, {}, true).and_return([other_instrument_hash, other_instrument_hash, other_instrument_hash])
          end

          it 'initiates a trade activity connection' do
            expect(trade_activity_module).to receive(:init_trade_activity_connection).with(app.settings.environment).and_return(trade_activity_connection)
            call_method
          end
          it 'calls `trade_activity_connection` with :get_trade_activity' do
            expect(trade_activity_connection).to receive(:call).with(:get_trade_activity, anything)
            call_method
          end
          it 'calls `trade_activity_connection` with a message tag of \'tradeRequest\'' do
            expect(trade_activity_connection).to receive(:call).with(anything, hash_including(message_tag: 'tradeRequest'))
            call_method
          end
          it 'calls `trade_activity_connection` with an appropriate soap_header' do
            expect(trade_activity_connection).to receive(:call).with(anything, hash_including(soap_header: {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}}))
            call_method
          end
          describe 'the `trade_activity_connection` message' do
            it 'includes the correct caller' do
              expect(trade_activity_connection).to receive(:call).with(anything, hash_including(message: hash_including('v11:caller' => [{'v11:id' => ENV['MAPI_FHLBSF_ACCOUNT']}])))
              call_method
            end
            it 'includes the fhlb_id of the member in question' do
              expect(trade_activity_connection).to receive(:call).with(anything, hash_including(message: hash_including('v1:tradeRequestParameters' => [include('v1:arrayOfCustomers' => [{'v1:fhlbId' => member_id}])])))
              call_method
            end
            it 'includes a start_date a hundred years in the past' do
              expect(trade_activity_connection).to receive(:call).with(anything, hash_including(message: hash_including('v1:tradeRequestParameters' => [include('v1:rangeOfSettlementDates' => [include('v1:startDate' => (today - 100.years).iso8601)])])))
              call_method
            end
            it 'includes an end_date a hundred years in the future' do
              expect(trade_activity_connection).to receive(:call).with(anything, hash_including(message: hash_including('v1:tradeRequestParameters' => [include('v1:rangeOfSettlementDates' => [include('v1:endDate' => (today + 100.years).iso8601)])])))
              call_method
            end
            it 'includes an array of all trade ids' do
              allow(trade_activity_module).to receive(:fetch_hashes).with(app.logger, historic_loc_query, {}, true).and_return([{'lc_transaction_number' => loc_trade_ids[0]}, {'lc_transaction_number' => loc_trade_ids[1]}, {'lc_transaction_number' => loc_trade_ids[2]}])
              allow(trade_activity_module).to receive(:fetch_hashes).with(app.logger, historic_activities_query, {}, true).and_return([{'calypso_internal_ref' => other_instrument_trade_ids[0]}, {'calypso_internal_ref' => other_instrument_trade_ids[1]}, {'calypso_internal_ref' => other_instrument_trade_ids[2]}])
              trade_id_array = []
              trade_ids = loc_trade_ids + other_instrument_trade_ids
              trade_ids.each do |trade_id|
                trade_id_array << {'v1:tradeId' => {'v1:tradeId' => trade_id}}
              end
              expect(trade_activity_connection).to receive(:call).with(anything, hash_including(message: hash_including('v1:tradeRequestParameters' => [include('v1:arrayOfTradeIds' => trade_id_array)])))
              call_method
            end
            it 'puts the trade ids first, then the customer id then the settlement date range' do
              expect(trade_activity_connection).to receive(:call) do |tag, options|
                expect(options[:message]['v1:tradeRequestParameters'].first.keys).to match(['v1:arrayOfTradeIds', 'v1:arrayOfCustomers', 'v1:rangeOfSettlementDates'])
                savon_response
              end
              call_method
            end
          end
          MAPI::Services::Member::TradeActivity::TODAYS_CREDIT_KEYS.each do |key|
            it "passes an array of hashes to `process_credit_activities` with the `#{key}` key set to the value content of the node found at the `#{key}` css node" do
              content = double('some content')
              allow(activity).to receive(:at_css).with(key).and_return(double('xml node', content: content))
              expect(trade_activity_module).to receive(:process_credit_activities).with(include(hash_including(key => content)))
              call_method
            end
          end
        end
      end
    end

    describe '`process_credit_activities` class method' do
      let(:today) { Time.zone.today }

      before do
        allow(Time.zone).to receive(:today).and_return(today)
      end

      it 'returns an empty array when passed an empty array' do
        expect(trade_activity_module.process_credit_activities([])).to eq([])
      end
      describe 'when passed an array of activities' do
        datetime_attrs = [['terminationDate', :termination_date]]
        date_attrs = [['tradeDate', :trade_date], ['fundingDate', :funding_date], ['maturityDate', :maturity_date]]
        string_attrs = [['instrumentType', :instrument_type], ['tradeID', :transaction_number],
                        ['productDescription', :product_description], ['terminationFullPartial', :termination_full_partial],
                        ['product', :product], ['subProduct', :sub_product], ['lifeCycleEvent', :life_cycle_event],
                        ['beneficiary', :beneficiary]]
        float_attrs = [['terminationPar', :termination_par], ['amount', :current_par], ['terminationFee', :termination_fee],
                       ['rate', :interest_rate]]
        let(:sentinel) { SecureRandom.hex }
        let(:activity) do
          activity = {}
          string_attrs.each {|attr| activity[attr.first] = double(attr.first, to_s: nil) }
          float_attrs.each {|attr| activity[attr.first] = double(attr.first, to_f: nil) }
          (datetime_attrs + date_attrs).each {|attr| activity[attr.first] = double(attr.first) }
          activity
        end
        let(:call_method) { trade_activity_module.process_credit_activities([activity]) }

        before do
          allow(Time.zone).to receive(:parse).and_return(instance_double(Time, to_date: nil))
          allow(DateTime).to receive(:strptime).and_return(instance_double(DateTime, to_date: nil))
          allow(trade_activity_module).to receive(:decimal_to_percentage_rate)
        end
        shared_examples 'an array with an invalid activity' do
          it 'does not include the invalid activity in the array of returned activities' do
            expect(call_method).to eq([])
          end
        end
        shared_examples 'an array with valid activities' do |skipped_attrs=[]|
          it 'returns an array of processed activities equal in length to the raw activities array' do
            n = rand(1..10)
            raw_activities = []
            n.times { raw_activities << activity }
            expect(trade_activity_module.process_credit_activities(raw_activities).length).to eq(n)
          end
          describe 'processing an activity' do
            describe 'processing the string attributes' do
              string_attrs.each do |attr|
                it "calls `to_s` on the `#{attr.first}` value in the raw activity" do
                  expect(activity[attr.first]).to receive(:to_s)
                  call_method
                end
                it "sets the `#{attr.last}` value in the processed activity to the processed `#{attr.first}` value" do
                  allow(activity[attr.first]).to receive(:to_s).and_return(sentinel)
                  results = call_method
                  expect(results.length).to be > 0
                  results.each do |processed_activity|
                    expect(processed_activity[attr.last]).to eq(sentinel)
                  end
                end
              end
            end
            describe 'processing the float attributes' do
              tested_attrs = (float_attrs - [['rate', :interest_rate]])
              tested_attrs = tested_attrs - [['terminationPar', :termination_par]] if skipped_attrs.include?(:termination_par)
              tested_attrs.each do |attr|
                it "calls `to_f` on the `#{attr.first}` value in the raw activity" do
                  expect(activity[attr.first]).to receive(:to_f)
                  call_method
                end
                it "sets the `#{attr.last}` value in the processed activity to the processed `#{attr.first}` value" do
                  allow(activity[attr.first]).to receive(:to_f).and_return(sentinel)
                  results = call_method
                  expect(results.length).to be > 0
                  results.each do |processed_activity|
                    expect(processed_activity[attr.last]).to eq(sentinel)
                  end
                end
              end
            end
            describe 'processing the `rate` attribute' do
              it 'calls `to_f` on the `rate` value in the raw activity' do
                expect(activity['rate']).to receive(:to_f)
                call_method
              end
              it 'calls `decimal_to_percentage_rate` with the rate float' do
                allow(activity['rate']).to receive(:to_f).and_return(sentinel)
                expect(trade_activity_module).to receive(:decimal_to_percentage_rate).with(sentinel)
                call_method
              end
              it 'sets the `interest_rate` value in the processed activity to the processed `rate` value' do
                float = instance_double(Float)
                allow(activity['rate']).to receive(:to_f).and_return(float)
                allow(trade_activity_module).to receive(:decimal_to_percentage_rate).with(float).and_return(sentinel)
                results = call_method
                expect(results.length).to be > 0
                results.each do |processed_activity|
                  expect(processed_activity[:interest_rate]).to eq(sentinel)
                end
              end
            end
            describe 'processing the `maintenanceFee` attribute' do
              let(:maintenance_fee_float) { instance_double(Float, :* => nil) }
              before do
                activity['maintenanceFee'] = double('maintenanceFee', to_f: rand)
              end
              it 'calls `to_f` on the `maintenanceFee` value in the raw activity' do
                expect(activity['maintenanceFee']).to receive(:to_f).and_return(maintenance_fee_float)
                call_method
              end
              it 'multiplies the `maintenanceFee` float by 10000' do
                expect(activity['maintenanceFee']).to receive(:to_f).and_return(maintenance_fee_float)
                expect(maintenance_fee_float).to receive(:*).with(10000)
                call_method
              end
              it 'sets the `maintenance_charge` value in the processed activity to the processed `maintenanceFee` value' do
                allow(activity['maintenanceFee']).to receive(:to_f).and_return(instance_double(Float, :* => sentinel))
                results = call_method
                expect(results.length).to be > 0
                results.each do |processed_activity|
                  expect(processed_activity[:maintenance_charge]).to eq(sentinel)
                end
              end
            end
            describe 'processing the date attributes' do
              let(:time) { instance_double(Time, to_date: nil) }
              tested_attrs = skipped_attrs.include?(:funding_date) ? date_attrs - [['fundingDate', :funding_date]] : date_attrs
              tested_attrs.each do |attr|
                it "calls `Time.zone.parse` with the `#{attr.first}` value in the raw activity" do
                  expect(Time.zone).to receive(:parse).with(activity[attr.first]).and_return(time)
                  call_method
                end
                it "calls `to_date` on the result of `Time.zone.parse`" do
                  allow(Time.zone).to receive(:parse).with(activity[attr.first]).and_return(time)
                  expect(time).to receive(:to_date)
                  call_method
                end
                it "sets the `#{attr.last}` value in the processed activity to the processed `#{attr.first}` value" do
                  allow(Time.zone).to receive(:parse).with(activity[attr.first]).and_return(instance_double(Time, to_date: sentinel))
                  results = call_method
                  expect(results.length).to be > 0
                  results.each do |processed_activity|
                    expect(processed_activity[attr.last]).to eq(sentinel)
                  end
                end
              end
            end
            describe 'processing the datetime attributes' do
              let(:datetime) { instance_double(DateTime, to_date: nil) }
              datetime_attrs.each do |attr|
                it "calls `DateTime.strptime` with the `#{attr.first}` value in the raw activity" do
                  expect(DateTime).to receive(:strptime).with(activity[attr.first], anything).and_return(datetime)
                  call_method
                end
                it "calls `DateTime.strptime` with the `'%m/%d/%Y'` as its format" do
                  expect(DateTime).to receive(:strptime).with(anything, '%m/%d/%Y').and_return(datetime)
                  call_method
                end
                it "calls `to_date` on the result of `DateTime.strptime`" do
                  allow(DateTime).to receive(:strptime).with(activity[attr.first], '%m/%d/%Y').and_return(datetime)
                  expect(datetime).to receive(:to_date)
                  call_method
                end
                it "sets the `#{attr.last}` value in the processed activity to the processed `#{attr.first}` value" do
                  allow(DateTime).to receive(:strptime).with(activity[attr.first], '%m/%d/%Y').and_return(instance_double(DateTime, to_date: sentinel))
                  results = call_method
                  expect(results.length).to be > 0
                  results.each do |processed_activity|
                    expect(processed_activity[attr.last]).to eq(sentinel)
                  end
                end
              end
            end
            describe 'processing the `lcNumber`' do
              let(:lc_number) { double('lcNumber', to_s: nil) }
              let(:other_lc_number) { double('lcNumber') }
              context 'when the raw value for `lcNumber` is an array' do
                before { activity['lcNumber'] = [lc_number, other_lc_number] }
                it 'calls `to_s` on the first value of the passed array' do
                  expect(lc_number).to receive(:to_s)
                  call_method
                end
                it 'ignores any other values in the array' do
                  expect(other_lc_number).not_to receive(:to_s)
                  call_method
                end
                it 'sets the `lc_number` value in the processed activity to the processed `lcNumber` value' do
                  allow(lc_number).to receive(:to_s).and_return(sentinel)
                  results = call_method
                  expect(results.length).to be > 0
                  results.each do |processed_activity|
                    expect(processed_activity[:lc_number]).to eq(sentinel)
                  end
                end
              end
              context 'when the raw value for `lcNumber` is not an array' do
                before { activity['lcNumber'] = lc_number }
                it 'calls `to_s` with the `lcNumber` value of the raw activity' do
                  expect(lc_number).to receive(:to_s)
                  call_method
                end
                it 'sets the `lc_number` value in the processed activity to the processed `lcNumber` value' do
                  allow(lc_number).to receive(:to_s).and_return(sentinel)
                  results = call_method
                  expect(results.length).to be > 0
                  results.each do |processed_activity|
                    expect(processed_activity[:lc_number]).to eq(sentinel)
                  end
                end
              end
            end

            describe 'processing the `lifeCycleEvent`' do
              it 'ignores LC products without a `lifeCycleEvent`' do
                activity['lifeCycleEvent'] = nil
                activity['product'] = 'LC'
                expect(call_method.length).to be(0)
              end
            end
          end
        end
        context 'when `status` is not included in the list of allowed statuses' do
          before { activity['status'] = 'Foo' }
          it_behaves_like 'an array with an invalid activity'
        end
        context 'when `status` is included in the list of allowed statuses' do
          before { activity['status'] = trade_activity_module::TODAYS_CREDIT_ARRAY.sample }
          context 'when the `instrument_type` is not `ADVANCE`' do
            it_behaves_like 'an array with valid activities'
          end
          context 'when the `instrument_type` is `ADVANCE`' do
            before { activity['instrumentType'] = 'ADVANCE' }
            context 'when the status is `EXERCISED`' do
              before { activity['status'] = 'EXERCISED'}
              it_behaves_like 'an array with valid activities'
            end
            context 'when the status is not `EXERCISED`' do
              before do
                activity['status'] = (trade_activity_module::TODAYS_CREDIT_ARRAY - ['EXERCISED']).sample
              end
              context 'when there is a `termination_par`' do
                before { allow(activity['terminationPar']).to receive(:to_f).and_return(activity['terminationPar']) }
                it_behaves_like 'an array with valid activities'
              end
              context 'when there is no `termination_par`' do
                before { activity.delete('terminationPar') }
                context 'when there is no `funding_date`' do
                  before { activity.delete('fundingDate') }
                  it_behaves_like 'an array with valid activities', [:termination_par, :funding_date]
                end
                context 'when there is a `funding_date`' do
                  context 'when the `funding_date` occurs earlier than today' do
                    before { allow(Time.zone).to receive(:parse).with(activity['fundingDate']).and_return(instance_double(Time, to_date: today - 1.day)) }
                    it_behaves_like 'an array with an invalid activity'
                  end
                  context 'when the `funding_date` occurs later than today' do
                    before do
                      allow(Time.zone).to receive(:parse).with(activity['fundingDate']).and_return(instance_double(Time, to_date: today + 1.day))
                      allow(sentinel).to receive(:<).and_return(false)
                    end
                    it_behaves_like 'an array with valid activities', [:termination_par]
                  end
                  context 'when the `funding_date` occurs today' do
                    before do
                      allow(Time.zone).to receive(:parse).with(activity['fundingDate']).and_return(instance_double(Time, to_date: today))
                      allow(sentinel).to receive(:<).and_return(false)
                    end
                    it_behaves_like 'an array with valid activities', [:termination_par]
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end