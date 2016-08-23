require 'rails_helper'

describe CalendarService do
  let(:request) { ActionDispatch::TestRequest.new }
  subject { described_class.new(request) }

  describe 'the `holidays` method' do
    let(:start_date) { instance_double(Date, iso8601: SecureRandom.hex) }
    let(:end_date) { instance_double(Date, iso8601: SecureRandom.hex) }
    let(:response) { {holidays: instance_double(Array)} }
    let(:call_method) { subject.holidays(start_date, end_date) }

    it 'fetches the `calendar_holidays` from the Rails cache with the proper key and expiry param' do
      expect(Rails.cache).to receive(:fetch).with(CacheConfiguration.key(:calendar_holidays), expires_in: CacheConfiguration.expiry(:calendar_holidays)).and_return(response)
      call_method
    end
    describe 'when `calendar_holidays` already exists in the Rails cache' do
      before { allow(Rails.cache).to receive(:fetch).and_return(response[:holidays]) }

      it 'does not call `get_hash`' do
        expect(subject).not_to receive(:get_hash)
        call_method
      end
      it 'returns the cached value' do
        expect(call_method).to eq(response[:holidays])
      end
    end

    describe 'when `calendar_holidays` does not yet exist in the Rails cache' do
      before do
        allow(Rails.cache).to receive(:fetch).and_yield
        allow(subject).to receive(:get_hash).and_return(response)
      end

      it 'converts the `start_date` param to `iso8601`' do
        expect(start_date).to receive(:iso8601)
        call_method
      end
      it 'converts the `end_date` param to `iso8601`' do
        expect(end_date).to receive(:iso8601)
        call_method
      end
      it 'calls `get_hash` with `:holidays` as the name arg' do
        expect(subject).to receive(:get_hash).with(:holidays, any_args)
        call_method
      end
      it 'calls `get_hash` with the proper MAPI endpoint' do
        expect(subject).to receive(:get_hash).with(anything, "calendar/holidays/#{start_date.iso8601}/#{end_date.iso8601}")
        call_method
      end
      it 'returns the `holidays` array from the results of `get_hash`' do
        expect(call_method).to eq(response[:holidays])
      end
      it 'raises an error when `get_hash` returns nil' do
        allow(subject).to receive(:get_hash).and_return(nil)
        expect{call_method}.to raise_error(StandardError, 'There has been an error and CalendarService#holidays has encountered nil. Check error logs.')
      end
    end
  end

  describe 'the `weekend_or_holiday?` method' do
    let(:call_method_saturday) { subject.weekend_or_holiday?("2016-08-06".to_date) }
    let(:call_method_sunday) { subject.weekend_or_holiday?("2016-08-07".to_date) }
    let(:call_method_holiday) { subject.weekend_or_holiday?("2016-08-08".to_date) }
    let(:call_method) { subject.weekend_or_holiday?("2016-08-09".to_date) }
    before do
      allow(subject).to receive(:holidays).with(anything, anything).and_return(["2016-08-08".to_date])
    end
    it 'returns `true` if date falls on a Saturday' do
      expect(call_method_saturday).to eq(true)
    end
    it 'returns `true` if date falls on a Sunday' do
      expect(call_method_sunday).to eq(true)
    end
    it 'returns `true` if date falls on a Sunday' do
      expect(call_method_holiday).to eq(true)
    end
    it 'returns `false` if date does not fall on a Saturday, Sunday or a Holiday' do
      expect(call_method).to eq(false)
    end
  end

  describe 'the `find_next_business_day` method' do
    let(:candidate) { Time.zone.today + rand(1..2).days }
    let(:delta) { 1 }
    let(:call_method) { subject.find_next_business_day(candidate, delta) }
    it 'returns calls weekend_or_holiday?' do
      expect(subject).to receive(:weekend_or_holiday?).with(candidate)
      call_method
    end
    it 'returns candidate+delta if weekend_or_holiday? is true' do
      allow(subject).to receive(:weekend_or_holiday?).with(candidate).at_least(1).and_return(true)
      allow(subject).to receive(:weekend_or_holiday?).with(candidate+delta).at_least(1).and_return(false)
      expect(call_method).to eq(candidate+delta)
    end
    it 'returns candidate if weekend_or_holiday? is false' do
      allow(subject).to receive(:weekend_or_holiday?).with(candidate).at_least(1).and_return(false)
      expect(call_method).to eq(candidate)
    end
  end
end