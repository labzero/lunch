require 'spec_helper'

describe MAPI::ServiceApp do
  include ActionView::Helpers::NumberHelper
  describe 'MAPI::Services::EtransactAdvances::Limits' do
    etransact_limits_module = MAPI::Services::EtransactAdvances::Limits
    let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }

    describe '`get_limits`' do
      let(:call_method) { etransact_limits_module.get_limits(app) }
      let(:some_status_data) {{"WHOLE_LOAN_ENABLED" => "N", "SBC_AGENCY_ENABLED" => "Y", "SBC_AAA_ENABLED" => "Y", "SBC_AA_ENABLED" => "Y",
                               "LOW_DAYS_TO_MATURITY" => 0, "HIGH_DAYS_TO_MATURITY" => 1, "MIN_ONLINE_ADVANCE" => "100000", "TERM_DAILY_LIMIT" => "201000000",
                               "PRODUCT_TYPE" => "VRC", "END_TIME" => "1700", "OVERRIDE_END_DATE" => "2006-01-01", "OVERRIDE_END_TIME" => "1700"}}
      before { allow(etransact_limits_module).to receive(:should_fake?).and_return(true) }

      context 'when `should_fake?` returns false' do
        before do
          allow(etransact_limits_module).to receive(:should_fake?).and_return(false)
          allow(MAPI::Services::EtransactAdvances).to receive(:fetch_hashes).and_return([some_status_data])
        end

        it 'calls `fetch_hashes` with the logger' do
          logger = instance_double(Logger)
          expect(MAPI::Services::EtransactAdvances).to receive(:fetch_hashes).with(app.logger, anything)
          call_method
        end
        describe 'calling `fetch_hashes` with the proper SQL' do
          describe 'the selected fields' do
            ['AO_TERM_BUCKET_ID', 'WHOLE_LOAN_ENABLED', 'SBC_AGENCY_ENABLED', 'SBC_AAA_ENABLED', 'SBC_AA_ENABLED', 'LOW_DAYS_TO_MATURITY',
             'HIGH_DAYS_TO_MATURITY', 'MIN_ONLINE_ADVANCE', 'TERM_DAILY_LIMIT', 'PRODUCT_TYPE', 'END_TIME', 'OVERRIDE_END_DATE'].each do |field|
              it "selects the `#{field}` field" do
                matcher = Regexp.new(/\A\s*SELECT.*\s+#{field}(,|\s+)/im)
                expect(MAPI::Services::EtransactAdvances).to receive(:fetch_hashes).with(anything, matcher)
                call_method
              end
            end
          end
          it 'selects from `WEB_ADM.AO_TERM_BUCKETS`' do
            matcher = Regexp.new(/\A\s*SELECT.+FROM\s+WEB_ADM.AO_TERM_BUCKETS/im)
            expect(MAPI::Services::EtransactAdvances).to receive(:fetch_hashes).with(anything, matcher)
            call_method
          end
        end
      end
      context 'when `should_fake?` returns true' do
        before { allow(etransact_limits_module).to receive(:should_fake?).and_return(true) }
        it 'parses the fake data file' do
          fake_file = double('fake data')
          allow(File).to receive(:read).with(File.join(MAPI.root, 'fakes', 'etransact_limits.json')).and_return(fake_file)
          expect(JSON).to receive(:parse).with(fake_file).and_return([])
          call_method
        end
      end
      describe 'adding the TERM to each bucket' do
        before { allow(JSON).to receive(:parse).and_call_original }
        etransact_limits_module::TERM_BUCKET_MAPPING.invert.each do |bucket_id, term|
          it "adds a TERM of `#{term}` when the `AO_TERM_BUCKET_ID` is `#{bucket_id}`" do
            allow(JSON).to receive(:parse).and_return([{'AO_TERM_BUCKET_ID' => bucket_id}])
            expect(call_method.length).to be > 0
            call_method.each do |bucket|
              expect(bucket['TERM']).to eq(term.to_s)
            end
          end
        end
      end
    end

    describe '`update_limits`' do
      let(:term) { SecureRandom.hex }
      let(:limits) {{term => double('bucket data')}}
      let(:call_method) { etransact_limits_module.update_limits(app, limits) }
      before { allow(etransact_limits_module).to receive(:should_fake?).and_return(true) }

      context 'when `should_fake?` returns true' do
        it 'returns true' do
          expect(call_method).to be true
        end
      end
      context 'when `should_fake?` returns false' do
        before { allow(etransact_limits_module).to receive(:should_fake?).and_return(false) }

        it 'executes code within a transaction where the `isolation` has been set to `:read_committed`' do
          expect(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
          call_method
        end
        it 'returns true if the transaction block executes without error' do
          allow(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
          expect(call_method).to be true
        end
        describe 'the transaction block' do
          let(:set_clause) { SecureRandom.hex }
          let(:bucket_id) { SecureRandom.hex }
          before do
            allow(ActiveRecord::Base).to receive(:transaction).and_yield
            allow(etransact_limits_module).to receive(:build_update_limit_set_clause).and_return(set_clause)
            allow(MAPI::Services::Rates::LoanTerms).to receive(:term_to_id).and_return(bucket_id)
            allow(etransact_limits_module).to receive(:quote)
            allow(etransact_limits_module).to receive(:execute_sql).and_return(true)
          end

          it 'calls `build_update_limit_set_clause` with the bucket data' do
            expect(etransact_limits_module).to receive(:build_update_limit_set_clause).with(limits[term]).and_return(set_clause)
            call_method
          end
          it 'calls `MAPI::Services::Rates::LoanTerms.term_to_id` with the term from the bucket' do
            expect(MAPI::Services::Rates::LoanTerms).to receive(:term_to_id).with(term).and_return(bucket_id)
            call_method
          end
          it 'raises an `MAPI::Shared::Errors::SQLError` if `execute_sql` does not succeed' do
            allow(etransact_limits_module).to receive(:execute_sql).and_return(false)
            expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, "Failed to update limit with term: #{term}")
          end
          it 'calls `execute_sql` with the logger' do
            expect(etransact_limits_module).to receive(:execute_sql).with(app.logger, anything).and_return(true)
            call_method
          end
          describe 'the update_limits_sql' do
            it 'updates the `WEB_ADM.AO_TERM_BUCKETS` table' do
              matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.AO_TERM_BUCKETS\s+/im)
              expect(etransact_limits_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
            it 'has a SET clause that consists of the result of `build_update_limit_set_clause`' do
              matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.AO_TERM_BUCKETS\s+.*SET\s+#{set_clause}\s+/im)
              expect(etransact_limits_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
            it 'calls `quote` on the result of `MAPI::Services::Rates::LoanTerms.term_to_id`' do
              expect(etransact_limits_module).to receive(:quote).with(bucket_id)
              call_method
            end
            it 'performs the update on the row where the `AO_TERM_BUCKET_ID` equals the quoted bucket id' do
              quoted_id = SecureRandom.hex
              allow(etransact_limits_module).to receive(:quote).with(bucket_id).and_return(quoted_id)
              matcher = Regexp.new(/\A\s*UPDATE.+WEB_ADM.AO_TERM_BUCKETS\s+.*SET\s+.+WHERE\s+AO_TERM_BUCKET_ID\s+=\s+#{quoted_id}\s*\z/im)
              expect(etransact_limits_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
          end
          it 'updates as many rows as there are buckets in the limit data it is passed' do
            n = rand(2..9)
            limits = {}
            n.times do
              limits[SecureRandom.hex] = double('bucket data')
            end
            expect(etransact_limits_module).to receive(:execute_sql).exactly(n).times.and_return(true)
            etransact_limits_module.update_limits(app, limits)
          end
        end
      end
    end

    describe '`build_update_limit_set_clause`' do
      let(:valid_field) { etransact_limits_module::VALID_LIMIT_FIELDS.sample }
      let(:string_field_name) { double('string field name', upcase: valid_field) }
      let(:field) { double('field name', to_s: string_field_name) }
      let(:processed_value) { SecureRandom.hex }
      let(:bucket_data) { {field => SecureRandom.hex} }
      let(:call_method) { etransact_limits_module.build_update_limit_set_clause(bucket_data) }
      before do
        allow(etransact_limits_module).to receive(:process_limit_value).and_return(processed_value)
      end
      it 'converts the bucket field name to a string' do
        expect(field).to receive(:to_s).and_return(string_field_name)
        call_method
      end
      it 'upcases the string version of the field name' do
        expect(string_field_name).to receive(:upcase).and_return(valid_field)
        call_method
      end
      it 'raises a `MAPI::Shared::Errors::InvalidFieldError` if the field name is not in the list of valid fields' do
        invalid_field_name = SecureRandom.hex
        allow(string_field_name).to receive(:upcase).and_return(invalid_field_name)
        expect{call_method}.to raise_error(MAPI::Shared::Errors::InvalidFieldError, "#{invalid_field_name} is an invalid field")
      end
      it 'calls `process_limit_value` with the bucket field name and value' do
        expect(etransact_limits_module).to receive(:process_limit_value).with(valid_field, bucket_data[field])
        call_method
      end
      it 'calls `quote` with the result of `process_limit_value`' do
        expect(etransact_limits_module).to receive(:quote).with(processed_value)
        call_method
      end
      it 'includes the key and quoted value in its returned string' do
        quoted_value = SecureRandom.hex
        allow(etransact_limits_module).to receive(:quote).and_return(quoted_value)
        matcher = Regexp.new(/(\A|\s+)#{valid_field}\s+=\s+#{quoted_value}(\s+|\z)/)
        expect(call_method).to match(matcher)
      end
      it 'joins all bucket together into a single string with `, `' do
        bucket_data = double('bucket data')
        allow(bucket_data).to receive(:collect).and_return(bucket_data)
        expect(bucket_data).to receive(:join).with(', ')
        etransact_limits_module.build_update_limit_set_clause(bucket_data)
      end
    end
    
    describe '`process_limit_value`' do
      let(:field_name) { double('some field name') }
      let(:value) { double('some value', to_s: string_value) }
      let(:string_value) { double('some string value', gsub: gsubbed_value) }
      let(:gsubbed_value) { double('some gsubbed string value', to_i: integer_value) }
      let(:integer_value) { double('some integer value') }
      let(:call_method) { etransact_limits_module.process_limit_value(field_name, value) }

      describe 'when the passed key is not explicitly called out in the case statement' do
        it 'returns the value it was passed' do
          expect(call_method).to eq(value)
        end
      end
      describe 'when the passed key is called called out in the switch statement' do
        ['MIN_ONLINE_ADVANCE', 'TERM_DAILY_LIMIT'].each do |field_name|
          describe "when the passed key is `#{field_name}`" do
            let(:call_method) { etransact_limits_module.process_limit_value(field_name, value) }
            it 'calls `to_s` on the value' do
              expect(value).to receive(:to_s).and_return(string_value)
              call_method
            end
            it 'removes commas from the string value' do
              expect(string_value).to receive(:gsub).with(',', '').and_return(gsubbed_value)
              call_method
            end
            it 'turns the processed string into an integer' do
              expect(gsubbed_value).to receive(:to_i).and_return(integer_value)
              call_method
            end
            it 'returns the integer' do
              expect(call_method).to eq(integer_value)
            end
            it 'returns an integer if passed an integer' do
              value = rand(1000..100000000)
              expect(etransact_limits_module.process_limit_value(field_name, value)).to eq(value)
            end
            it 'returns the integer verson of a string' do
              value = rand(1000..100000000)
              string_value = number_with_delimiter(value)
              expect(etransact_limits_module.process_limit_value(field_name, string_value)).to eq(value)
            end
          end
        end
      end
    end
  end
end