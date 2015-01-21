require 'spec_helper'

describe ControllerHelper do
  describe '`range_picker_default_presets` method' do
    let(:custom_start_date) { Date.new(2013,1,1) }
    let(:custom_end_date) { Date.new(2015,12,16) }
    let(:this_month_start_date) { Date.new(2015,1,1) }
    let(:this_month_end_date) { Date.new(2015,1,16) }
    let(:last_month_start_date) { Date.new(2014,12,1) }
    let(:last_month_end_date) { Date.new(2014,12,31) }
    before do
      stub_const('ControllerHelper::THIS_MONTH_START', this_month_start_date)
      stub_const('ControllerHelper::THIS_MONTH_END', this_month_end_date)
      stub_const('ControllerHelper::LAST_MONTH_START', last_month_start_date)
      stub_const('ControllerHelper::LAST_MONTH_END', last_month_end_date)
    end
    it 'should build a presets array' do
      expect(helper.range_picker_default_presets(last_month_start_date, last_month_end_date).length).to eq(3)
      helper.range_picker_default_presets(custom_start_date, custom_end_date).each do |preset|
          expect(preset).to be_kind_of(Hash)
          expect(preset[:start_date]).to be_kind_of(Date)
          expect(preset[:end_date]).to be_kind_of(Date)
      end
    end
    it 'should flag the first preset as the default if the start and end args match the current month to date' do
      expect(helper.range_picker_default_presets(this_month_start_date, this_month_end_date).first[:is_default]).to eq(true)
    end
    it 'should flag the second preset as the default if the start and end args match the start and end of last month' do
      expect(helper.range_picker_default_presets(last_month_start_date, last_month_end_date)[1][:is_default]).to eq(true)
    end
    it 'should flag the custom preset as the default if the start and end args fail to match any other preset' do
      expect(helper.range_picker_default_presets(custom_start_date, custom_end_date).last[:is_default]).to eq(true)
    end
    it 'should flag the last preset as being the custom preset' do
      expect(helper.range_picker_default_presets(last_month_start_date, last_month_end_date).last[:is_custom]).to eq(true)
    end
  end

end