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

  describe '`fhlb_date_standard_numeric` method' do
    let(:date) {Date.new(2015,1,20)}
    it 'converts a date into a string following the MM-DD-YYYY convention' do
      expect(helper.fhlb_date_standard_numeric(date)).to eq('01-20-2015')
    end
  end

  describe '`fhlb_date_long_alpha` method' do
    let(:date) {Date.new(2015,1,2)}
    it 'converts a date into an alphanumeric string following the `Month d, YYYY` format' do
      expect(helper.fhlb_date_long_alpha(date)).to eq('January 2, 2015')
    end
  end
end