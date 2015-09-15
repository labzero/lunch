require 'spec_helper'
require 'date'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'Trade Activity' do
    let(:advances) { get "/member/#{MEMBER_ID}/active_advances"; JSON.parse(last_response.body) }
    it 'should return expected advances detail hash where value could not be nil' do
      advances.each do |row|
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
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
      end
      it 'should return active advances', vcr: {cassette_name: 'trade_activity_service'} do
        advances.each do |row|
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
        get "/member/#{MEMBER_ID}/active_advances"
        expect(last_response.status).to eq(503)
      end
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
        allow(MAPI::Services::Member::TradeActivity).to receive(:init_trade_connection).and_return(true)
        MAPI::Services::Member::TradeActivity.class_variable_set(:@@trade_connection, trade_connection)
      end
      MAPI::Services::Member::TradeActivity::TODAYS_ADVANCES_ARRAY.each do |advance_type|
        it "adds the daily advance activity for all members if a trade has type `#{advance_type}`" do
          trade_1_amount = rand(1000..999999) + rand()
          trade_2_amount = rand(1000..999999)  + rand()
          allow(included_trade_1).to receive(:at_css).with('tradeHeader status').and_return(double('xml node', content: advance_type))
          allow(included_trade_1).to receive(:at_css).with('advance par amount').and_return(double('xml node', content: trade_1_amount))
          allow(included_trade_2).to receive(:at_css).with('tradeHeader status').and_return(double('xml node', content: advance_type))
          allow(included_trade_2).to receive(:at_css).with('advance par amount').and_return(double('xml node', content: trade_2_amount))
          allow(excluded_trade).to receive(:at_css).with('tradeHeader status').and_return(double('xml node', content: 'foo'))
          expect(current_daily_total).to eq(trade_1_amount + trade_2_amount)
        end
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
    let(:todays_advances) { get "/member/#{MEMBER_ID}/todays_advances"; JSON.parse(last_response.body) }
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
    describe 'in the production environment' do
      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
      end
      it 'should return active advances', vcr: {cassette_name: 'trade_activity_service'} do
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
        get "/member/#{MEMBER_ID}/todays_advances"
        expect(last_response.status).to eq(503)
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
      get "/member/#{MEMBER_ID}/todays_credit_activity"
    end
    it 'returns an array of activity objects', vcr: {cassette_name: 'todays_credit_activity'} do
      allow(MAPI::ServiceApp).to receive(:environment).and_return(:production)
      get "/member/#{MEMBER_ID}/todays_credit_activity"
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
      get "/member/#{MEMBER_ID}/todays_credit_activity"
      expect(last_response.status).to eq(503)
    end
    %w(development test).each do |env|
      describe "in the #{env} environment" do
        let(:todays_credit_activity) { MAPI::Services::Member::TradeActivity.todays_credit_activity(env, MEMBER_ID) }
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

    describe 'in the production environment' do
      let(:savon_response) { double('savon response', doc: double('doc', remove_namespaces!: nil, xpath: activity_hash)) }
      let(:trade_activity_connection) { double('trade_connection', call: savon_response) }
      let(:todays_credit_activity) { MAPI::Services::Member::TradeActivity.todays_credit_activity(:production, MEMBER_ID) }
      it 'initiates a Savon client connection' do
        expect(Savon).to receive(:client).and_return(trade_activity_connection)
        todays_credit_activity
      end
      describe 'with the trade_activity_connection stubbed' do
        before do
          MAPI::Services::Member::TradeActivity.class_variable_set(:@@trade_activity_connection, trade_activity_connection)
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