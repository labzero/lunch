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
    it 'should return market data rates', vcr: {cassette_name: 'market_data_cof_service'} do
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
end
