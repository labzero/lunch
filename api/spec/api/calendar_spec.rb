require 'spec_helper'


describe MAPI::ServiceApp do
  subject { MAPI::Services::Calendar }

  describe 'GET `/holidays`' do
    today = Time.zone.today
    let(:environment) { instance_double(String) }
    let(:start_date) { today + rand(1..30).days }
    let(:end_date) { start_date + rand(30..90).days }
    let(:response) { instance_double(Array) }
    let(:logger) { double('MAPI logger', error: nil) }
    let(:make_request) { get "/calendar/holidays/#{start_date.iso8601}/#{end_date.iso8601}" }
    let(:response_body) { make_request; JSON.parse(last_response.body).with_indifferent_access }
    let(:response_status) { make_request; last_response.status }

    before do
      allow_any_instance_of(MAPI::ServiceApp).to receive(:logger).and_return(logger)
      allow(MAPI::Services::Rates::Holidays).to receive(:holidays).and_return(response)
    end

    it 'calls `MAPI::Services::Rates::Holidays.holidays` with the `logger`' do
      expect(MAPI::Services::Rates::Holidays).to receive(:holidays).with(logger, any_args)
      make_request
    end
    it 'calls `MAPI::Services::Rates::Holidays.holidays` with the `environment`' do
      expect(MAPI::Services::Rates::Holidays).to receive(:holidays).with(anything, MAPI::ServiceApp.environment, any_args)
      make_request
    end
    it 'calls `MAPI::Services::Rates::Holidays.holidays` with the `start_date`' do
      expect(MAPI::Services::Rates::Holidays).to receive(:holidays).with(anything, anything, start_date, anything)
      make_request
    end
    it 'calls `MAPI::Services::Rates::Holidays.holidays` with the `end_date`' do
      expect(MAPI::Services::Rates::Holidays).to receive(:holidays).with(anything, anything, anything, end_date)
      make_request
    end
    it 'returns a status of 200' do
      expect(response_status).to eq(200)
    end
    it 'returns the result of `MAPI::Services::Rates::Holidays.holidays` as a JSON hash with a `holidays` key' do
      make_request
      expect(last_response.body).to eq({holidays: response}.to_json)
    end

    describe 'error handling' do
      describe 'when the `end_date` occurs before the `start_date`' do
        let(:end_date) { start_date - rand(30..90).days }

        it 'returns a 400' do
          expect(response_status).to eq(400)
        end
        it 'logs an error message' do
          expect(logger).to receive(:error).with('Invalid date range: start_date must occur earlier than end_date or on the same day')
          make_request
        end
        it 'returns an error code of `invalid_date_range` in its body' do
          expect(response_body[:errors]).to include('invalid_date_range')
        end
      end
    end
  end
end