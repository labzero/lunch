require 'spec_helper'
require 'date'

describe MAPI::Services::Rates::MarketDataRates do
  describe "market data rates in the development environment" do
    let(:market_data_rates) { subject.get_market_cof_rates(:development, anything, anything, anything)}
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
    let(:market_data_rates) { subject.get_market_cof_rates(:production, [], '1week', 'whole')}
    let(:call_method) { market_data_rates }
    let(:mds_connection) { double('mds_connection', operations: nil) }
    let(:fhlbsfresponse) { double('fhlbsfresponse', at_css: nil, present?: true) }
    let(:response) { double('response') }
    let(:content) {'sometype'}
    let(:frequency) { double('frequency')}
    let(:frequency_unit) { double('frequency_unit')}
    let(:term) { double('term')}
    let(:today) { Time.zone.today }
    let(:maturity_date) { today + rand(3..1095).days }
    let(:number_of_weekends) { (Time.zone.today..maturity_date).to_a.select {|k| [0,6].include?(k.wday)} }
    let(:days_to_maturity) { ((maturity_date.to_date - today).to_i - number_of_weekends.count()).to_s + 'day' }
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
    describe 'building the MDS message', vcr: {cassette_name: 'market_data_cof_service'} do
      let(:mds_connection) { MAPI::Services::Rates.init_mds_connection(:production) }
      it 'includes the caller ID' do
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v11:caller' => [{'v11:id' => ENV['MAPI_COF_ACCOUNT']}])) ).and_call_original
        call_method
      end
      it 'includes one request for each COF type' do
        expect(MAPI::Services::Rates::COF_TYPES.length).to be > 0
        requests = MAPI::Services::Rates::COF_TYPES.collect do |type|
          include(
            'v1:marketData' => [include('v12:name' => type, 'v12:pricingGroup' => [{'v12:id' => 'Live'}])],
            'v1:caller' => [{'v11:id' => ENV['MAPI_COF_ACCOUNT']}]
          )
        end
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v1:requests' => [{'v1:fhlbsfMarketDataRequest' => requests}])) ).and_call_original
        call_method
      end
      it 'includes interval with frequency and frequencyUnit for each tenor' do
        term_mapping = { term => {frequency: frequency, frequency_unit: frequency_unit }}
        stub_const 'MAPI::Shared::Constants::TERM_MAPPING', term_mapping
        requests = MAPI::Services::Rates::COF_TYPES.collect do
          include('v1:marketData' => [include('v12:data' => [{'v12:FhlbsfDataPoint' => ['v12:tenor' => ['v12:interval' => [{'v13:frequency' => frequency,'v13:frequencyUnit' => frequency_unit}]]]}])])
        end
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v1:requests' => [{'v1:fhlbsfMarketDataRequest' => requests}])) ).and_call_original
        subject.get_market_cof_rates(:production, [], term, 'whole')
      end
      it 'includes interval with frequency and frequencyUnit for custom' do
        requests = MAPI::Services::Rates::COF_TYPES.collect do
          include('v1:marketData' => [include('v12:data' => [{'v12:FhlbsfDataPoint' => ['v12:tenor' => ['v12:interval' => [{'v13:frequency' => ((maturity_date.to_date - today).to_i - number_of_weekends.count()).to_s,'v13:frequencyUnit' => 'D'}]]]}])])
        end
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v1:requests' => [{'v1:fhlbsfMarketDataRequest' => requests}])) ).and_call_original
        subject.get_market_cof_rates(:production, [], days_to_maturity, 'whole', nil, maturity_date)
      end
      it 'includes customRollingDay = 31 for whole loan types' do
        requests = MAPI::Services::Rates::COF_TYPES.collect do
          include('v1:marketData' => [include('v12:customRollingDay' => 31)])
        end
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v1:requests' => [{'v1:fhlbsfMarketDataRequest' => requests}])) ).and_call_original
        call_method
      end
      it 'includes customRollingDay = 0 for sbc loan types' do
        requests = MAPI::Services::Rates::COF_TYPES.collect do
          include('v1:marketData' => [include('v12:customRollingDay' => 0)])
        end
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v1:requests' => [{'v1:fhlbsfMarketDataRequest' => requests}])) ).and_call_original
        subject.get_market_cof_rates(:production, [], '1week', 'agency')
      end
      it 'includes dayCountBasis = ACT/360 for sbc loan types' do
        requests = MAPI::Services::Rates::COF_TYPES.collect do
          include('v1:marketData' => [include('v12:dayCountBasis' => 'ACT/360')])
        end
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v1:requests' => [{'v1:fhlbsfMarketDataRequest' => requests}])) ).and_call_original
        subject.get_market_cof_rates(:production, [], '1week', 'agency')
      end
      it 'includes paymentFrequency with frequency = 6 and frequencyUnit = M for sbc loan types' do
        requests = MAPI::Services::Rates::COF_TYPES.collect do
          include('v1:marketData' => [include('v12:paymentFrequency' => [{ 'v13:frequency' => 6, 'v13:frequencyUnit'=> 'M'}])])
        end
        expect(mds_connection).to receive(:call).with(:get_market_data, include(message: include('v1:requests' => [{'v1:fhlbsfMarketDataRequest' => requests}])) ).and_call_original
        subject.get_market_cof_rates(:production, [], '1week', 'agency')
      end
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
