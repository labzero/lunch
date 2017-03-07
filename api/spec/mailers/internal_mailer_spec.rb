require 'spec_helper'

describe MAPI::Mailers::InternalMailer do
  describe 'class methods' do
    describe '`send_rate_band_alert`' do
      let(:type) { instance_double(Symbol, 'A Loan Type', to_s: instance_double(String, 'A Stringified Loan Type')) }
      let(:term) { instance_double(Symbol, 'A Loan Term', to_s: instance_double(String, 'A Stringified Loan Term')) }
      let(:rate) { instance_double(Numeric, 'A Rate') }
      let(:starting_rate) { instance_double(Numeric, 'A Start-of-day Rate') }
      let(:rate_band_details) { instance_double(Hash, 'rate details') }
      let(:request_id) { instance_double(String, 'A UUID') }
      let(:user_id) { instance_double(String, 'A User ID') }
      let(:call_method) { described_class.send_rate_band_alert(type, term, rate, starting_rate, rate_band_details, request_id, user_id) }

      describe 'calls `perform_later` on the `MailerJob`' do
        it 'supplies `InternalMailer` as the `class name' do
          expect(MailerJob).to receive(:perform_later).with('InternalMailer', any_args)
          call_method
        end
        it 'supplies `exceeds_rate_band` as the method name' do
          expect(MailerJob).to receive(:perform_later).with(anything, 'exceeds_rate_band', any_args)
          call_method
        end
        it 'supplies `request_id` as the request ID' do
          expect(MailerJob).to receive(:perform_later).with(anything, anything, anything, request_id, any_args)
          call_method
        end
        it 'supplies `starting_rate` as `start_of_day_rate` in the rate details' do
          expect(MailerJob).to receive(:perform_later).with(anything, anything, include(start_of_day_rate: starting_rate), any_args)
          call_method
        end
        it 'supplies `current_rate` as `rate` in the rate details' do
          expect(MailerJob).to receive(:perform_later).with(anything, anything, include(rate: rate), any_args)
          call_method
        end
        it 'supplies a stringified `term` as `term` in the rate details' do
          expect(MailerJob).to receive(:perform_later).with(anything, anything, include(term: term.to_s), any_args)
          call_method
        end
        it 'supplies a stringified `type` as `type` in the rate details' do
          expect(MailerJob).to receive(:perform_later).with(anything, anything, include(type: type.to_s), any_args)
          call_method
        end
        it 'supplies `rate_band_details` as `rate_band_info` in the rate details' do
          expect(MailerJob).to receive(:perform_later).with(anything, anything, include(rate_band_info: rate_band_details), any_args)
          call_method
        end
        it 'supplies `user_id` as the user ID' do
          expect(MailerJob).to receive(:perform_later).with(anything, anything, anything, anything, user_id, any_args)
          call_method
        end
        it 'supplies `nil` as the user ID if none is provided' do
          expect(MailerJob).to receive(:perform_later).with(anything, anything, anything, anything, nil, any_args)
          described_class.send_rate_band_alert(type, term, rate, starting_rate, rate_band_details, request_id)
        end
      end
    end
  end
end