require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do
  let(:member_id) { 750 }
  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'Trade Activity' do
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
      it 'should return active advances', vcr: {cassette_name: 'trade_activity_service'} do
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
        end
      end
      it 'should return active advances for large members', vcr: {cassette_name: 'trade_activity_service', :allow_playback_repeats => true} do
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
        expect{call_method}.to raise_error
      end
      it 'should return Internal Service Error, if trade service is unavailable for large members', vcr: {cassette_name: 'trade_activity_service_unavailable'} do
        allow(MAPI::Services::Member::TradeActivity).to receive(:is_large_member).and_return(true)
        expect{call_method}.to raise_error
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
      let(:empty_result_set) {double('Oracle Result Set', fetch: nil)}
      let(:ods_code) {double('ods_code')}
      it 'return nil if there are no records found' do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(double(empty_result_set))
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
    string_attributes = [['instrument_type','instrumentType'], ['status', 'status'], ['transaction_number', 'tradeID'], ['product_description', 'productDescription'], ['termination_full_partial', 'terminationFullPartial'], ['product', 'product'], ['sub_product', 'subProduct']]
    float_attributes = [['termination_par', 'terminationPar'], ['current_par', 'amount'], ['interest_rate', 'rate'], ['termination_fee', 'terminationFee']]
    date_attributes = [['funding_date', 'fundingDate'], ['maturity_date', 'maturityDate']]

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
      expect(activity[:funding_date]).to eq('2013-03-19')
      expect(activity[:maturity_date]).to eq('2015-09-14')
      expect(activity[:product_description]).to eq('LC LC LC')
      expect(activity[:instrument_type]).to eq('LC')
      expect(activity[:status]).to eq('VERIFIED')
      expect(activity[:termination_par]).to be_nil
      expect(activity[:termination_fee]).to be_nil
      expect(activity[:termination_full_partial]).to be_nil
      expect(activity[:product]).to eq('LC')
      expect(activity[:sub_product]).to eq('LC')
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
          it "formats the `#{float_attribute.first}` as a string" do
            expect(attribute).to receive(:to_f)
            allow(activity).to receive(:[]).with(float_attribute.last).and_return(attribute)
            todays_credit_activity
          end
        end
        date_attributes.each do |date_attribute|
          it "formats the `#{date_attribute.first}` as a string" do
            allow(attribute).to receive(:[]=).and_return(attribute)
            expect(Time.zone).to receive(:parse).with(attribute).and_return(double('time object', :to_date => nil))
            allow(activity).to receive(:[]).with(date_attribute.last).and_return(attribute)
            todays_credit_activity
          end
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
          it "formats the `#{float_attribute.first}` as a string" do
            expect(attribute).to receive(:to_f)
            allow(activity).to receive(:at_css).with(float_attribute.last).and_return(double('xml node', content: attribute))
            todays_credit_activity
          end
        end
        date_attributes.each do |date_attribute|
          it "formats the `#{date_attribute.first}` as a string" do
            expect(Time.zone).to receive(:parse).with(attribute).and_return(double('time object', :to_date => nil))
            allow(activity).to receive(:at_css).with(date_attribute.last).and_return(double('xml node', content: attribute))
            todays_credit_activity
          end
        end
      end
    end
  end
end