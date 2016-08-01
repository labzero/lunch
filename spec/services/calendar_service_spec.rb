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
end