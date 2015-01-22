require 'spec_helper'

describe CustomFormattingHelper do
  describe '`fhlb_formatted_currency` method' do
    it 'converts a number into the approved FHLB currency format' do
      expect(helper.fhlb_formatted_currency(465465465)).to eq('$465,465,465')
    end
    it 'omits the dollar-sign if it is passed the number 0' do
      expect(helper.fhlb_formatted_currency(0)).to eq('0')
    end
  end
end