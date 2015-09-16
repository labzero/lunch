require 'spec_helper'
require 'date'

describe MAPI::Services::Rates::MarketDataRates do
  describe "market data rates in the development environment" do
    let(:market_data_rates) { subject.get_market_cof_rates(:development, anything)}
    it 'should return market data rates' do
      expect(market_data_rates.length).to be >=1
      expect(market_data_rates['COF_FIXED']).to be_kind_of(String)
      expect(market_data_rates['COF_3L']).to be_kind_of(String)
      expect(market_data_rates['ADVANCE_BENCHMARK']).to be_kind_of(String)
      expect(market_data_rates['MU_WL']).to be_kind_of(String)
      expect(market_data_rates['MU_AGCY']).to be_kind_of(String)
      expect(market_data_rates['MU_AA']).to be_kind_of(String)
      expect(market_data_rates['MU_AAA']).to be_kind_of(String)
    end
  end
  describe "market data rates in the production environment" do
    let(:market_data_rates) { subject.get_market_cof_rates(:production, '1week')}
    let(:call_method) { market_data_rates }
    let(:mds_connection) { double('mds_connection', operations: nil) }
    let(:fhlbsfresponse) { double('fhlbsfresponse', at_css: nil, present?: true) }
    let(:response) { double('response') }
    let(:content) {'sometype'}
    it 'should return market data rates', vcr: {cassette_name: 'market_data_cof_service'} do
      expect(market_data_rates.length).to be >=1
      expect(market_data_rates['COF_FIXED']).to eq('0.94')
      expect(market_data_rates['COF_3L']).to eq('-25')
      expect(market_data_rates['ADVANCE_BENCHMARK']).to eq('0.94')
      expect(market_data_rates['MU_WL']).to eq('17')
      expect(market_data_rates['MU_AGCY']).to eq('17')
      expect(market_data_rates['MU_AA']).to eq('17')
      expect(market_data_rates['MU_AAA']).to eq('17')
    end
    it 'calls `init_mds_connection`' do
      expect(MAPI::Services::Rates).to receive(:init_mds_connection).with(:production)
      call_method
    end
    it 'should raise an error that response is missing' do
      allow(MAPI::Services::Rates).to receive(:init_mds_connection).with(:production).and_return(mds_connection)
      allow(response).to receive_message_chain(:doc, :remove_namespaces!)
      allow(response).to receive_message_chain(:doc, :xpath).and_return({})
      allow(mds_connection).to receive(:call).and_return(response)
      expect{call_method}.to raise_error('Missing Response')
    end
    it 'should raise an error that data is missing' do
      allow(MAPI::Services::Rates).to receive(:init_mds_connection).with(:production).and_return(mds_connection)
      allow(response).to receive_message_chain(:doc, :remove_namespaces!)
      allow(response).to receive_message_chain(:doc, :xpath).and_return(fhlbsfresponse)
      allow(fhlbsfresponse).to receive_message_chain(:[], :css)
      allow(mds_connection).to receive(:call).and_return(response)
      expect{call_method}.to raise_error('Missing Data')
    end
    it "should raise and exception, if mds service is unavailable", vcr: {cassette_name: 'market_data_cof_service_unavailable'} do
      begin
        market_data_rates
      rescue Savon::Error => error
        expect(error).to_not be(nil)
      end
    end
  end
end
