require 'spec_helper'

describe MAPI::ServiceApp do
  include ActionView::Helpers::NumberHelper
  describe 'MAPI::Services::EtransactAdvances::ShutoffTimes' do
    shutoff_times_module = MAPI::Services::EtransactAdvances::ShutoffTimes
    let(:app) { instance_double(MAPI::ServiceApp, logger: double('logger')) }

    describe 'class methods' do
      describe '`get_shutoff_times_by_type`' do
        let(:call_method) { shutoff_times_module.get_shutoff_times_by_type(app) }
        before { allow(shutoff_times_module).to receive(:should_fake?).and_return(true) }

        it 'calls `should_fake?` with the app passed as an argument' do
          expect(shutoff_times_module).to receive(:should_fake?).with(app).and_return(true)
          call_method
        end

        context 'when `should_fake?` returns true' do
          before { allow(shutoff_times_module).to receive(:should_fake?).and_return(true) }
          it 'calls `fake` with `etransact_shutoff_times_by_type`' do
            expect(shutoff_times_module).to receive(:fake).with('etransact_shutoff_times_by_type').and_return([])
            call_method
          end
        end
        context 'when `should_fake?` returns false' do
          before { allow(shutoff_times_module).to receive(:should_fake?).and_return(false) }
          it 'calls `fetch_hashes` with the app logger' do
            expect(shutoff_times_module).to receive(:fetch_hashes).with(app.logger, any_args).and_return([])
            call_method
          end
          it 'calls `fetch_hashes` with an empty hash for the mapping arg' do
            expect(shutoff_times_module).to receive(:fetch_hashes).with(anything, anything, {}, anything).and_return([])
            call_method
          end
          it 'calls `fetch_hashes` with true for the downcase keys arg' do
            expect(shutoff_times_module).to receive(:fetch_hashes).with(anything, anything, anything, true).and_return([])
            call_method
          end
          describe 'the SQL query' do
            describe 'the selected fields' do
              ['PRODUCT_TYPE', 'END_TIME'].each do |field|
                it "selects the `#{field}` field" do
                  matcher = Regexp.new(/\A\s*SELECT.*\s+#{field}(?:,|\s+)/im)
                  expect(shutoff_times_module).to receive(:fetch_hashes).with(anything, matcher, anything, anything).and_return([])
                  call_method
                end
              end
            end
            it 'selects from `WEB_ADM.AO_TYPE_SHUTOFF`' do
              matcher = Regexp.new(/\A\s*SELECT.+FROM\s+WEB_ADM.AO_TYPE_SHUTOFF/im)
              expect(shutoff_times_module).to receive(:fetch_hashes).with(anything, matcher, anything, anything).and_return([])
              call_method
            end
          end
        end
        it 'downcases the `product_types`' do
          product_type = double('product type')
          allow(shutoff_times_module).to receive(:fake).and_return([{'product_type' => product_type}])
          expect(product_type).to receive(:downcase)
          call_method
        end
        it 'returns a hash with the `product_type` as keys and the corresponding `end_time`s as their values' do
          product_type_1 = SecureRandom.hex.downcase
          end_time_1 = instance_double(String)
          product_type_2 = SecureRandom.hex.downcase
          end_time_2 = instance_double(String)
          raw_shutoff_times = [
            {'product_type' => product_type_1, 'end_time' => end_time_1},
            {'product_type' => product_type_2, 'end_time' => end_time_2}
          ]
          allow(shutoff_times_module).to receive(:fake).and_return(raw_shutoff_times)
          expect(call_method).to eq({
            product_type_1 => end_time_1,
            product_type_2 => end_time_2
          })
        end
      end

      describe '`get_early_shutoffs`' do
        let(:call_method) { shutoff_times_module.get_early_shutoffs(app) }
        before { allow(shutoff_times_module).to receive(:should_fake?).and_return(true) }

        it 'calls `should_fake?` with the app passed as an argument' do
          expect(shutoff_times_module).to receive(:should_fake?).with(app).and_return(true)
          call_method
        end

        context 'when `should_fake?` returns true' do
          before { allow(shutoff_times_module).to receive(:should_fake?).and_return(true) }
          it 'calls `fake_hashes` with `etransact_early_shutoff_times`' do
            expect(shutoff_times_module).to receive(:fake_hashes).with('etransact_early_shutoff_times').and_return([])
            call_method
          end
        end
        context 'when `should_fake?` returns false' do
          before { allow(shutoff_times_module).to receive(:should_fake?).and_return(false) }
          it 'calls `fetch_hashes` with the app logger' do
            expect(shutoff_times_module).to receive(:fetch_hashes).with(app.logger, any_args).and_return([])
            call_method
          end
          it 'calls `fetch_hashes` with an empty hash for the mapping arg' do
            expect(shutoff_times_module).to receive(:fetch_hashes).with(anything, anything, {}, anything).and_return([])
            call_method
          end
          it 'calls `fetch_hashes` with true for the downcase keys arg' do
            expect(shutoff_times_module).to receive(:fetch_hashes).with(anything, anything, anything, true).and_return([])
            call_method
          end
          describe 'the SQL query' do
            describe 'the selected fields' do
              ['EARLY_SHUTOFF_DATE', 'FRC_SHUTOFF_TIME', 'VRC_SHUTOFF_TIME', 'DAY_OF_MESSAGE', 'DAY_BEFORE_MESSAGE'].each do |field|
                it "selects the `#{field}` field" do
                  matcher = Regexp.new(/\A\s*SELECT.*\s+#{field}(?:,|\s+)/im)
                  expect(shutoff_times_module).to receive(:fetch_hashes).with(anything, matcher, anything, anything).and_return([])
                  call_method
                end
              end
            end
            it 'selects from `WEB_ADM.AO_TYPE_EARLY_SHUTOFF`' do
              matcher = Regexp.new(/\A\s*SELECT.+FROM\s+WEB_ADM.AO_TYPE_EARLY_SHUTOFF/im)
              expect(shutoff_times_module).to receive(:fetch_hashes).with(anything, matcher, anything, anything).and_return([])
              call_method
            end
          end
        end
        describe 'formatting the `early_shutoff_date`' do
          let(:early_shutoff_iso8601) { double('early shutoff date') }
          let(:early_shutoff_date) { instance_double(Date, iso8601: early_shutoff_iso8601) }
          let(:early_shutoff_string) { instance_double(String, to_date: early_shutoff_date) }
          let(:early_shutoff) {{'early_shutoff_date' => early_shutoff_string}}
          before { allow(shutoff_times_module).to receive(:fake_hashes).and_return([early_shutoff]) }

          it 'calls `to_date` on the `early_shutoff_date` value for each scheduled shutoff' do
            expect(early_shutoff_string).to receive(:to_date).and_return(early_shutoff_date)
            call_method
          end
          it 'calls `iso8601` on the datified `early_shutoff_date` value' do
            expect(early_shutoff_date).to receive(:iso8601)
            call_method
          end
          it 'sets the `early_shutoff_date` value to the iso8601-formatted date' do
            expect(call_method.first['early_shutoff_date']).to eq(early_shutoff_iso8601)
          end
        end
        ['day_of_message', 'day_before_message'].each do |message|
          describe "formatting the `#{message}`" do
            let(:p1) { SecureRandom.hex }
            let(:p2) { SecureRandom.hex }
            let(:escaped_newline_string) { "#{p1}\\n#{p2}" }
            let(:unescaped_newline_string) { "#{p1}\n#{p2}" }

            it 'unescapes newline characters it finds in the message' do
              allow(shutoff_times_module).to receive(:fake_hashes).and_return([{message => escaped_newline_string}])
              expect(call_method.first[message]).to eq(unescaped_newline_string)
            end
            it 'does nothing to unescaped newline characters it finds in the message' do
              allow(shutoff_times_module).to receive(:fake_hashes).and_return([{message => unescaped_newline_string}])
              expect(call_method.first[message]).to eq(unescaped_newline_string)
            end
            it 'does nothing if the value is nil' do
              allow(shutoff_times_module).to receive(:fake_hashes).and_return([{message => nil}])
              expect(call_method.first[message]).to be nil
            end
          end
        end
      end

      describe '`schedule_early_shutoff`' do
        let(:early_shutoff) { instance_double(Hash, with_indifferent_access: nil) }
        let(:call_method) { shutoff_times_module.schedule_early_shutoff(app, early_shutoff) }
        before do
          allow(shutoff_times_module).to receive(:should_fake?).and_return(true)
          allow(shutoff_times_module).to receive(:validate_early_shutoff)
        end

        context 'operations independent of the result of `should_fake?`' do
          it 'ensures the `early_shutoff` arg can be queried with indifferent access' do
            expect(early_shutoff).to receive(:with_indifferent_access)
            call_method
          end
          it 'validates the `early_shutoff` arg' do
            allow(early_shutoff).to receive(:with_indifferent_access).and_return(early_shutoff)
            expect(shutoff_times_module).to receive(:validate_early_shutoff).with(early_shutoff)
            call_method
          end
          it 'calls `should_fake?` with the app passed as an argument' do
            expect(shutoff_times_module).to receive(:should_fake?).with(app).and_return(true)
            call_method
          end
        end
        context 'when `should_fake?` returns true' do
          before { allow(shutoff_times_module).to receive(:should_fake?).and_return(true) }
          it 'calls returns true' do
            expect(call_method).to be true
          end
        end
        context 'when `should_fake?` returns false' do
          let(:early_shutoff) {{
            early_shutoff_date: instance_double(String),
            frc_shutoff_time: instance_double(String),
            vrc_shutoff_time: instance_double(String),
            day_of_message: instance_double(String),
            day_before_message: instance_double(String)
          }}
          let(:quoted_values) {{
            early_shutoff_date: SecureRandom.hex,
            frc_shutoff_time: SecureRandom.hex,
            vrc_shutoff_time: SecureRandom.hex,
            day_of_message: SecureRandom.hex,
            day_before_message: SecureRandom.hex
          }}
          let(:call_method) { shutoff_times_module.schedule_early_shutoff(app, early_shutoff) }
          before do
            allow(shutoff_times_module).to receive(:should_fake?).and_return(false)
            allow(shutoff_times_module).to receive(:execute_sql).and_return(true)
            allow(shutoff_times_module).to receive(:quote)
          end
          it 'returns true if `execute_sql` is successful' do
            expect(call_method).to be true
          end
          it 'raises an error containing the `early_shutoff_date` if `execute_sql` is nil' do
            allow(shutoff_times_module).to receive(:execute_sql).and_return(nil)
            expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, "Failed to schedule the early shutoff for date: #{early_shutoff[:early_shutoff_date]}")
          end
          it 'raises an error containing the `early_shutoff_date` if `execute_sql` is false' do
            allow(shutoff_times_module).to receive(:execute_sql).and_return(false)
            expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, "Failed to schedule the early shutoff for date: #{early_shutoff[:early_shutoff_date]}")
          end
          it 'calls `execute_sql` with the logger' do
            expect(shutoff_times_module).to receive(:execute_sql).with(app.logger, anything).and_return(true)
            call_method
          end
          describe 'the SQL passed to `execute_sql`' do
            it 'INSERTs INTO the WEB_ADM.AO_TYPE_EARLY_SHUTOFF table' do
              matcher = Regexp.new(/\A\s*INSERT\s+INTO\s+WEB_ADM\.AO_TYPE_EARLY_SHUTOFF\s+/im)
              expect(shutoff_times_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
            it 'calls out the fields in which to insert the values in the correct order' do
              matcher = Regexp.new(/\A\s*INSERT\s+INTO\s+WEB_ADM\.AO_TYPE_EARLY_SHUTOFF\s+\(\s+EARLY_SHUTOFF_DATE\s*,\s*FRC_SHUTOFF_TIME\s*,\s*VRC_SHUTOFF_TIME\s*,\s*DAY_OF_MESSAGE\s*,\s*DAY_BEFORE_MESSAGE\s*\)/im)
              expect(shutoff_times_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
            %i(early_shutoff_date frc_shutoff_time vrc_shutoff_time day_of_message day_before_message).each do |attribute|
              it "quotes the `#{attribute}`" do
                expect(shutoff_times_module).to receive(:quote).with(early_shutoff[attribute])
                call_method
              end
            end
            it 'calls out the quoted values to insert in the correct order' do
              early_shutoff.each do |key, value|
                allow(shutoff_times_module).to receive(:quote).with(value).and_return(quoted_values[key])
              end
              matcher = Regexp.new(/\A\s*INSERT.+VALUES\s*\(\s*TO_DATE\s*\(\s*#{quoted_values[:early_shutoff_date]}\s*,\s*'YYYY-MM-DD'\s*\)\s*,\s*#{quoted_values[:frc_shutoff_time]}\s*,\s*#{quoted_values[:vrc_shutoff_time]}\s*,\s*#{quoted_values[:day_of_message]}\s*,\s*#{quoted_values[:day_before_message]}\s*\)\s*\z/im)
              expect(shutoff_times_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
          end
        end
      end

      describe '`validate_early_shutoff`' do
        let(:shutoff) {{
          early_shutoff_date: instance_double(String, to_s: instance_double(String, match: true)),
          frc_shutoff_time: instance_double(String, to_s: instance_double(String, match: true)),
          vrc_shutoff_time: instance_double(String, to_s: instance_double(String, match: true)),
          day_of_message: instance_double(String, to_s: ''),
          day_before_message: instance_double(String, to_s: '')
        }}
        let(:sentinel) { instance_double(String, match: true) }
        let(:call_method) { shutoff_times_module.validate_early_shutoff(shutoff) }

        it 'returns nil if no errors are raised' do
          expect(call_method).to be nil
        end
        {
          early_shutoff_date: {
            format: shutoff_times_module::REPORT_PARAM_DATE_FORMAT,
            error_message: 'early_shutoff_date must follow ISO8601 standards: YYYY-MM-DD'
          },
          frc_shutoff_time: {
            format: shutoff_times_module::TIME_24_HOUR_FORMAT,
            error_message: 'frc_shutoff_time must be a 4-digit, 24-hour time representation with values between `0000` and `2359`'
          },
          vrc_shutoff_time: {
            format: shutoff_times_module::TIME_24_HOUR_FORMAT,
            error_message: 'vrc_shutoff_time must be a 4-digit, 24-hour time representation with values between `0000` and `2359`'
          }
        }.each do |attr, test_data|
          describe "validating the `#{attr}`" do
            before { allow(shutoff[attr]).to receive(:to_s).and_return(sentinel) }

            it "ensures the `#{attr}` is a string" do
              expect(shutoff[attr]).to receive(:to_s).and_return(sentinel)
              call_method
            end
            it "checks to see if the `#{attr}` matches the `#{test_data[:format]}` format" do
              expect(sentinel).to receive(:match).with(test_data[:format]).and_return(true)
              call_method
            end
            it "raises an error if `#{attr}` does not match the format" do
              allow(sentinel).to receive(:match).and_return(false)
              expect{call_method}.to raise_error(shutoff_times_module::InvalidFieldError, test_data[:error_message]) do |error|
                expect(error.code).to eq(attr)
                expect(error.value).to eq(shutoff[attr])
              end
            end
          end
        end
        [:day_of_message, :day_before_message].each do |attr|
          describe "validating the `#{attr}`" do
            let(:mock_length) { double('length', :> => false) }
            before do
              allow(sentinel).to receive(:length).and_return(mock_length)
              allow(shutoff[attr]).to receive(:to_s).and_return(sentinel)
            end

            it "ensures the `#{attr}` is a string" do
              expect(shutoff[attr]).to receive(:to_s).and_return(sentinel)
              call_method
            end
            it "checks to see if the length of the `#{attr}` is greater than `#{shutoff_times_module::SHUTOFF_MESSAGE_MAX_LENGTH}`" do
              expect(mock_length).to receive(:>).with(shutoff_times_module::SHUTOFF_MESSAGE_MAX_LENGTH)
              call_method
            end
            it "raises an error if the length of the `#{attr}` is greater than `#{shutoff_times_module::SHUTOFF_MESSAGE_MAX_LENGTH}`" do
              allow(sentinel).to receive(:length).and_return(shutoff_times_module::SHUTOFF_MESSAGE_MAX_LENGTH + 1)
              expect{call_method}.to raise_error(shutoff_times_module::InvalidFieldError, "#{attr} cannot be longer than #{shutoff_times_module::SHUTOFF_MESSAGE_MAX_LENGTH} characters") do |error|
                expect(error.code).to eq(attr)
                expect(error.value).to eq(shutoff[attr])
              end
            end
          end
        end
      end
    end
  end
end