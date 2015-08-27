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
end