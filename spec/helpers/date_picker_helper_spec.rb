require 'spec_helper'

describe DatePickerHelper do
  describe '`default_dates_hash` method' do
    let(:today) { Date.new(2013,1,1) }
    let(:picker_preset_hash) {double(Hash)}
    let(:zone) {double('Time.zone')}
    let(:now) {double('Time.zone.now')}
    before do
      allow(now).to receive(:to_date).at_least(1).and_return(today)
      allow(zone).to receive(:now).at_least(1).and_return(now)
      allow(Time).to receive(:zone).at_least(1).and_return(zone)
    end
    it 'returns a hash with keys for `today`, `this_month_start`, `last_month_start`, and `last_month_end`' do
      expect(helper.default_dates_hash[:today]).to eq(today)
      expect(helper.default_dates_hash[:this_month_start]).to eq(today.beginning_of_month)
      expect(helper.default_dates_hash[:last_month_start]).to eq(today.beginning_of_month - 1.month)
      expect(helper.default_dates_hash[:last_month_end]).to eq((today.beginning_of_month - 1.month).end_of_month)
      expect(helper.default_dates_hash[:this_year_start]).to eq(today.beginning_of_year)
    end
  end

  describe '`date_picker_presets` method' do
    let(:custom_start_date) { Date.new(2013,1,1) }
    let(:custom_end_date) { Date.new(2015,12,16) }
    let(:this_month_start_date) { Date.new(2015,1,1) }
    let(:today) { Date.new(2015,1,16) }
    let(:last_month_start_date) { Date.new(2014,12,1) }
    let(:last_month_end_date) { Date.new(2014,12,31) }
    let(:default_dates) {{
      this_month_start: this_month_start_date,
      today: today,
      last_month_start: last_month_start_date,
      last_month_end: last_month_end_date
    }}
    before do
      expect(helper).to receive(:default_dates_hash).at_least(:once).and_return(default_dates)
    end
    it 'should build a presets array for a date range picker by default' do
      expect(helper.date_picker_presets(last_month_start_date, last_month_end_date).length).to eq(3)
      helper.date_picker_presets(custom_start_date, custom_end_date).each do |preset|
          expect(preset).to be_kind_of(Hash)
          expect(preset[:start_date]).to be_kind_of(Date)
          expect(preset[:end_date]).to be_kind_of(Date)
      end
    end
    it 'should build a presets array for a single date picker if no end_date is passed' do
      expect(helper.date_picker_presets(last_month_start_date).length).to eq(3)
      helper.date_picker_presets(custom_start_date).each do |preset|
        expect(preset).to be_kind_of(Hash)
        expect(preset[:start_date]).to be_kind_of(Date)
        expect(preset[:end_date]).to be_kind_of(Date)
      end
    end
    it 'should build a presets array with custom presets if they are passed as a hash' do
      custom_start_1 = Date.new(2012,1,1)
      custom_end_1 = Date.new(2012,12,31)
      custom_label_1 = 'label 1'
      custom_start_2 = Date.new(2013,1,1)
      custom_end_2 = Date.new(2013,12,31)
      custom_label_2 = 'label 2'
      preset_options = {
          :first_preset => {
              :label => custom_label_1,
              :start_date => custom_start_1,
              :end_date => custom_end_1
          },
          :second_preset => {
              :label => custom_label_2,
              :start_date => custom_start_2,
              :end_date => custom_end_2
          }
      }
      expect(helper.date_picker_presets(custom_start_date, custom_end_date, preset_options)[0][:start_date]).to eq(custom_start_1)
      expect(helper.date_picker_presets(custom_start_date, custom_end_date, preset_options)[0][:end_date]).to eq(custom_end_1)
      expect(helper.date_picker_presets(custom_start_date, custom_end_date, preset_options)[0][:label]).to eq(custom_label_1)
      expect(helper.date_picker_presets(custom_start_date, custom_end_date, preset_options)[1][:start_date]).to eq(custom_start_2)
      expect(helper.date_picker_presets(custom_start_date, custom_end_date, preset_options)[1][:end_date]).to eq(custom_end_2)
      expect(helper.date_picker_presets(custom_start_date, custom_end_date, preset_options)[1][:label]).to eq(custom_label_2)
    end
    it 'should flag the first preset as the default if the start and end args match the current month to date' do
      expect(helper.date_picker_presets(this_month_start_date, today).first[:is_default]).to eq(true)
    end
    it 'should flag the second preset as the default if the start and end args match the start and end of last month' do
      expect(helper.date_picker_presets(last_month_start_date, last_month_end_date)[1][:is_default]).to eq(true)
    end
    it 'should flag the custom preset as the default if the start and end args fail to match any other preset' do
      expect(helper.date_picker_presets(custom_start_date, custom_end_date).last[:is_default]).to eq(true)
    end
    it 'should flag the last preset as being the custom preset' do
      expect(helper.date_picker_presets(last_month_start_date, last_month_end_date).last[:is_custom]).to eq(true)
    end
  end

end