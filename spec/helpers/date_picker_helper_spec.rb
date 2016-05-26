require 'rails_helper'

describe DatePickerHelper do
  let(:today) { Date.new(2013, 1, 1) }
  let(:zone) {double('Time.zone', today: today)}
  before do
    allow(Time).to receive(:zone).at_least(1).and_return(zone)
  end

  describe '`default_dates_hash` method' do
    it 'returns a hash with keys for `today`, `this_month_start`, `last_30_days`, `last_month_start`, `last_month_end`, `this_year_start`, `last_year_start`, and `last_year_end`' do
      expect(helper.default_dates_hash[:today]).to eq(today)
      expect(helper.default_dates_hash[:last_30_days]).to eq(today - 1.month)
      expect(helper.default_dates_hash[:this_month_start]).to eq(today.beginning_of_month)
      expect(helper.default_dates_hash[:last_month_start]).to eq(today.beginning_of_month - 1.month)
      expect(helper.default_dates_hash[:last_month_end]).to eq((today.beginning_of_month - 1.month).end_of_month)
      expect(helper.default_dates_hash[:next_month_end]).to eq((today + 1.month).end_of_month)
      expect(helper.default_dates_hash[:this_year_start]).to eq(today.beginning_of_year)
      expect(helper.default_dates_hash[:last_year_start]).to eq((today - 1.year).beginning_of_year)
      expect(helper.default_dates_hash[:last_year_end]).to eq((today - 1.year).end_of_year)
    end
    it 'defaults to using today for its reference date' do
      expect(helper.default_dates_hash[:today]).to eq(today)
    end
    it 'allows the reference date to be passed in' do
      reference_date = today - 1.month
      expect(helper.default_dates_hash(reference_date)[:today]).to eq(reference_date)
    end
  end

  describe '`current_quarter` method' do
    it 'returns a hash with keys for `quarter`, and `year`' do
      expect(helper.current_quarter[:quarter]).to eq((today.month / 3.0).ceil)
      expect(helper.current_quarter[:year]).to eq(today.year)
    end
  end

  describe '`last_quarter` method' do
    q1_date = Date.new(2013, 1, 1)
    q2_date = Date.new(2013, 4, 1)
    q3_date = Date.new(2013, 7, 1)
    q4_date = Date.new(2013, 12, 1)

    describe 'when the current quarter is a q1_date' do
      let(:today) { q1_date }
      before do
        allow(Time).to receive(:zone).at_least(1).and_return(double('Time.zone', today: today))
      end
      it 'returns 4 as the quarter' do
        expect(helper.last_quarter[:quarter]).to eq(4)
      end
      it 'returns last year as the year' do
        expect(helper.last_quarter[:year]).to eq(2012)
      end
    end
    [q2_date, q3_date, q4_date].each do |date|
      describe "when the current quarter is a #{date}" do
        let(:today) {date}
        before do
          allow(Time).to receive(:zone).at_least(1).and_return(double('Time.zone', today: today))
        end
        it 'returns the current quarter minus 1 as the quarter' do
          expect(helper.last_quarter[:quarter]).to eq(((today.month / 3.0).ceil) - 1)
        end
        it 'returns the current year as the year' do
          expect(helper.last_quarter[:year]).to eq(today.year)
        end
      end
    end
  end

  describe '`quarter_start_and_end_dates` method' do
    let(:year) { 2013 }

    it 'returns January 1 of the given year as the start_date for quarter 1' do
      expect(helper.quarter_start_and_end_dates(1, year)[:start_date]).to eq(Date.new(year, 1, 1))
    end
    it 'returns March 31 of the given year as the end_date for quarter 1' do
      expect(helper.quarter_start_and_end_dates(1, year)[:end_date]).to eq(Date.new(year, 3, 31))
    end
    it 'returns April 1 of the given year as the start_date for quarter 2' do
      expect(helper.quarter_start_and_end_dates(2, year)[:start_date]).to eq(Date.new(year, 4, 1))
    end
    it 'returns June 30 of the given year as the end_date for quarter 2' do
      expect(helper.quarter_start_and_end_dates(2, year)[:end_date]).to eq(Date.new(year, 6, 30))
    end
    it 'returns July 1 of the given year as the start_date for quarter 3' do
      expect(helper.quarter_start_and_end_dates(3, year)[:start_date]).to eq(Date.new(year, 7, 1))
    end
    it 'returns September 30 of the given year as the end_date for quarter 3' do
      expect(helper.quarter_start_and_end_dates(3, year)[:end_date]).to eq(Date.new(year, 9, 30))
    end
    it 'returns October 1 of the given year as the start_date for quarter 4' do
      expect(helper.quarter_start_and_end_dates(4, year)[:start_date]).to eq(Date.new(year, 10, 1))
    end
    it 'returns December 31 of the given year as the end_date for quarter 4' do
      expect(helper.quarter_start_and_end_dates(4, year)[:end_date]).to eq(Date.new(year, 12, 31))
    end
  end

  describe '`date_picker_presets` method' do
    let(:start_date) { Date.new(2013, 1, 1) }
    let(:end_date) { Date.new(2015, 12, 16) }
    let(:date_history) { 6.months }
    let(:min_date) { Time.zone.today - date_history }
    let(:max_date) { Time.zone.today }
    let(:presets_array_single) {double('presets array', each: nil)}
    let(:presets_array_range) {double('presets array', each: nil)}
    describe 'when passed only a start date' do
      before do
        allow(helper).to receive(:date_picker_single).with(start_date, nil, nil).and_return(presets_array_single)
      end
      it 'should return the result of `date_picker_single`' do
        expect(helper.date_picker_presets(start_date)).to eq(presets_array_single)
      end
      it 'marks a preset as `is_default` if its start_date matches the the provided start date' do
        presets_array = [{start_date: start_date}, {start_date: 'some other date'}]
        allow(helper).to receive(:date_picker_single).and_return(presets_array)
        expect(helper.date_picker_presets(start_date).first[:is_default]).to be(true)
        expect(helper.date_picker_presets(start_date).last[:is_default]).to be_falsey
      end
      it 'passes min_date to `date_picker_single` if a date_history argument is provided' do
        expect(helper).to receive(:date_picker_single).with(start_date, min_date, nil).and_return(presets_array_single)
        helper.date_picker_presets(start_date, nil, date_history, nil)
      end
      it 'passes max_date to `date_picker_single` if a max_date argument is provided' do
        expect(helper).to receive(:date_picker_single).with(start_date, nil, max_date).and_return(presets_array_single)
        helper.date_picker_presets(start_date, nil, nil, max_date)
      end
    end
    describe 'when passed a start date and an end date' do
      before do
        allow(helper).to receive(:date_picker_range).with(start_date, end_date, nil, nil).and_return(presets_array_range)
      end
      it 'should return the result of `date_picker_range`' do
        expect(helper.date_picker_presets(start_date, end_date)).to eq(presets_array_range)
      end
      it 'marks a preset as `is_default` if its start_date and end date matches the the provided start date' do
        presets_array = [{start_date: start_date, end_date: end_date}, {start_date: 'some other date', end_date: end_date}, {start_date: start_date, end_date: 'some other date'}]
        allow(helper).to receive(:date_picker_range).and_return(presets_array)
        expect(helper.date_picker_presets(start_date, end_date).first[:is_default]).to be(true)
        expect(helper.date_picker_presets(start_date, end_date)[1][:is_default]).to be_falsey
        expect(helper.date_picker_presets(start_date, end_date).last[:is_default]).to be_falsey
      end
      it 'passes min_date to `date_picker_range` if given' do
        expect(helper).to receive(:date_picker_range).with(start_date, end_date, min_date, nil).and_return(presets_array_range)
        helper.date_picker_presets(start_date, end_date, date_history)
      end
      it 'passes max_date to `date_picker_range` if given' do
        expect(helper).to receive(:date_picker_range).with(start_date, end_date, nil, max_date).and_return(presets_array_range)
        helper.date_picker_presets(start_date, end_date, nil, max_date)
      end
    end
    describe 'when passed exclude' do
      it 'should return the result of `date_picker_single` and remove today hash' do
        expect(helper.date_picker_presets(start_date, nil, nil, nil, [:today]).first[:id]).to eq(:month_end)
      end
      it 'should return the result of `date_picker_single` and remove today and month_end hash' do
        expect(helper.date_picker_presets(start_date, nil, nil, nil, [:today, :month_end]).first[:id]).to eq(:year_end)
      end
    end
  end

  describe '`date_picker_range` method' do
    let(:start_date) { Date.new(2013, 1, 1) }
    let(:end_date) { Date.new(2015, 12, 16) }
    let(:min_date) { Date.new(2012, 6, 1) }
    let(:max_date) { Time.zone.today - 1.day }
    it 'returns an array of presets' do
      expect(helper.date_picker_range(start_date, end_date, nil, nil)).to be_kind_of(Array)
    end
    describe 'a preset object' do
      it 'has a label' do
        helper.date_picker_range(start_date, end_date, nil, nil).each do |preset|
          expect(preset[:label]).to be_kind_of(String)
        end
      end
      it 'has a start_date' do
        helper.date_picker_range(start_date, end_date, nil, nil).each do |preset|
          expect(preset[:start_date]).to be_kind_of(Date)
        end
      end
      it 'has an end_date' do
        helper.date_picker_range(start_date, end_date, nil, nil).each do |preset|
          expect(preset[:end_date]).to be_kind_of(Date)
        end
      end
    end
    it 'excludes any presets that have a start date less than the min date provided' do
      helper.date_picker_range(start_date, today, min_date, nil).each do |preset|
        expect(preset[:start_date]).to be >= min_date
      end
    end
    it 'excludes any presets that have a start date greater than the max date provided' do
      helper.date_picker_range(start_date, today, nil, max_date).each do |preset|
        expect(preset[:start_date]).to be <= max_date
      end
    end
  end

  describe '`date_picker_single` method' do
    let(:start_date) { Date.new(2013, 1, 1) }
    let(:min_date) { Date.new(2012, 6, 1) }
    let(:max_date) { Time.zone.today - 1.day }
    let(:ids) { %i(today month_end quarter_end year_end custom) }
    it 'returns an array of presets' do
      expect(helper.date_picker_single(start_date, nil, nil)).to be_kind_of(Array)
    end
    describe 'a preset object' do
      it 'has a label' do
        presets = helper.date_picker_single(start_date, nil, nil)
        expect(presets.count).to be >= 1
        presets.each do |preset|
          expect(preset[:label]).to be_kind_of(String)
        end
      end
      it 'has a label' do
        presets = helper.date_picker_single(start_date, nil, nil)
        expect(presets.count).to be >= 1
        presets.each do |preset|
          expect(preset[:label]).to be_kind_of(String)
        end
      end
      it 'has a start_date' do
        presets = helper.date_picker_single(start_date, nil, nil)
        expect(presets.count).to be >= 1
        presets.each do |preset|
          expect(preset[:start_date]).to be_kind_of(Date)
        end
      end
      it 'has an end_date' do
        presets = helper.date_picker_single(start_date, nil, nil)
        expect(presets.count).to be >= 1
        presets.each do |preset|
          expect(preset[:end_date]).to be_kind_of(Date)
        end
      end
      it 'has correct id name' do
        presets = helper.date_picker_single(start_date, nil, nil)
        expect(presets.count).to be >= 1
        presets.each do |preset|
          expect(ids.include?(preset[:id])).to be(true)
        end
      end
      it 'has at least one id' do
        expect(helper.date_picker_single(start_date, nil, nil).first[:id]).to eq(:today)
      end
    end
    it 'excludes any presets that have a start date less than the min date provided' do
      helper.date_picker_single(start_date, min_date, nil).each do |preset|
        expect(preset[:start_date]).to be >= min_date
      end
    end
    it 'excludes any presets that have a start date greater than the max date provided' do
      helper.date_picker_single(start_date, nil, max_date).each do |preset|
        expect(preset[:start_date]).to be <= max_date
      end
    end
    describe '`most_recent` preset' do
      let(:most_recent_preset) { helper.date_picker_single(start_date, min_date, max_date).select {|preset| preset[:id] == :most_recent}.first }
      it 'adds a preset for the `max_date` if its not today' do
        expect(most_recent_preset).to be_present
      end
      it 'has the `max_date` for its `start_date`' do
        expect(most_recent_preset[:start_date]).to be(max_date)
      end
      it 'has the `max_date` for its `end_date`' do
        expect(most_recent_preset[:end_date]).to be(max_date)
      end
      it 'has the `max_date` for its label' do
        formatted_max_date = double(Date)
        allow(helper).to receive(:fhlb_date_standard_numeric).with(max_date).and_return(formatted_max_date)
        expect(most_recent_preset[:label]).to be(formatted_max_date)
      end
      it 'does not add a preset for the `max_date` if its today' do
        presets = helper.date_picker_single(start_date, min_date, Time.zone.today).each do |preset|
          expect(preset[:id]).to_not be(:most_recent)
        end
      end
    end
  end

end