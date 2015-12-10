require 'rails_helper'

describe FinancialInstrumentHelper, type: :helper do
  describe '`financial_instrument_standardize` method' do
    it 'converts string with WL at the end to Wholeloan' do
      expect(helper.financial_instrument_standardize('Some Text WL')).to eq('Some Text Wholeloan')
    end
    it 'ignores conversion if the WL string is not at the end of the input' do
      expect(helper.financial_instrument_standardize('Some WL Text')).to eq('Some WL Text')
    end
  end
end