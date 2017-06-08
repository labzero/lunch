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
    end
  end
end