require 'rails_helper'

describe CalendarService do
  let(:request) { ActionDispatch::TestRequest.new }
  subject { described_class.new(request) }

  describe 'the `holidays` method' do
    let(:start_date) { instance_double(Date, iso8601: SecureRandom.hex) }
    let(:end_date) { instance_double(Date, iso8601: SecureRandom.hex) }
    let(:holidays) { instance_double(Array) }
    let(:call_method) { subject.holidays(start_date, end_date) }

    before { allow(subject).to receive(:get_hash) }

    it_should_behave_like 'a MAPI backed service object method', :holidays, [Time.zone.today, Time.zone.today + 3.months]

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
      allow(subject).to receive(:get_hash).and_return({holidays: holidays})
      expect(call_method).to eq(holidays)
    end
    it 'returns nil when `get_hash` returns nil' do
      expect(call_method).to be_nil
    end
  end
end