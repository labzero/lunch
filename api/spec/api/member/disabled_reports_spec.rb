require 'spec_helper'

describe MAPI::ServiceApp do
  let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
  let(:disabled_reports_module) { MAPI::Services::Member::DisabledReports }

  describe 'class methods' do
    describe '`global_disabled_ids`' do
      let(:disabled_global_ids) { Array.new(4){ rand(1000..9999)}.uniq }
      let(:global_string_array_result) { disabled_global_ids.collect{ |id| id.to_s} }
      let(:call_method) { disabled_reports_module.global_disabled_ids(app) }
      before { allow(disabled_reports_module).to receive(:should_fake?).and_return(true) }

      it 'calls `should_fake?` with the app' do
        expect(disabled_reports_module).to receive(:should_fake?).with(app).and_return(true)
        call_method
      end
      context 'when `should_fake?` returns false' do
        before { allow(disabled_reports_module).to receive(:should_fake?).and_return(false) }

        it 'calls `fetch_objects` with the logger from the app' do
          expect(disabled_reports_module).to receive(:fetch_objects).with(app.logger, anything).and_return([])
          call_method
        end
        describe 'the SQL for fetching the global flags' do
          it 'SELECTs the WEB_FLAG_ID' do
            matcher = Regexp.new(/\A\s*SELECT.*\s+WEB_FLAG_ID\s+/im)
            expect(disabled_reports_module).to receive(:fetch_objects).with(anything, matcher).and_return([])
            call_method
          end
          it 'selects FROM the WEB_ADM.WEB_DATA_FLAGS table' do
            matcher = Regexp.new(/\A\s*SELECT.*\s+FROM\s+WEB_ADM.WEB_DATA_FLAGS\s+/im)
            expect(disabled_reports_module).to receive(:fetch_objects).with(anything, matcher).and_return([])
            call_method
          end
          it 'selects rows WHERE the WEB_FLAG_VALUE is `N`' do
            matcher = Regexp.new(/\A\s*SELECT.*\s+FROM.*\s+WHERE\s+WEB_FLAG_VALUE\s*=\s*'N'\s*.*\z/im)
            expect(disabled_reports_module).to receive(:fetch_objects).with(anything, matcher).and_return([])
            call_method
          end
        end
        it 'returns the result of fetching the global disabled flags as an array of integers' do
          allow(disabled_reports_module).to receive(:fetch_objects).and_return(global_string_array_result)
          expect(call_method).to eq(disabled_global_ids)
        end
      end
      context 'when `should_fake?` returns true' do
        before { allow(disabled_reports_module).to receive(:should_fake?).and_return(true) }

        it 'calls `fake` with `global_report_availability`' do
          expect(disabled_reports_module).to receive(:fake).with('global_report_availability').and_return([])
          call_method
        end
        it 'returns the result of fetching the global disabled flags as an array of integers' do
          expect(disabled_reports_module).to receive(:fake).with('global_report_availability').and_return(global_string_array_result)
          expect(call_method).to eq(disabled_global_ids)
        end
      end
    end

    describe '`update_global_ids`' do
      let(:web_flag) {{
        web_flag_id: SecureRandom.hex,
        visible: SecureRandom.hex
      }}
      let(:call_method) { disabled_reports_module.update_global_ids(app, [web_flag]) }
      before { allow(disabled_reports_module).to receive(:should_fake?).and_return(true) }

      it 'calls `should_fake?` with the app' do
        expect(disabled_reports_module).to receive(:should_fake?).with(app).and_return(true)
        call_method
      end
      context 'when `should_fake?` returns false' do
        before { allow(disabled_reports_module).to receive(:should_fake?).and_return(false) }

        it 'executes code within a transaction where the `isolation` has been set to `:read_committed`' do
          expect(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
          call_method
        end
        it 'returns true if the transaction block executes without error' do
          allow(ActiveRecord::Base).to receive(:transaction).with(isolation: :read_committed)
          expect(call_method).to be true
        end
        describe 'the transaction block' do
          before do
            allow(disabled_reports_module).to receive(:quote)
            allow(disabled_reports_module).to receive(:execute_sql).and_return(true)
            allow(ActiveRecord::Base).to receive(:transaction).and_yield
          end

          it 'calls `execute_sql` with the logger from the app' do
            expect(disabled_reports_module).to receive(:execute_sql).with(app.logger, anything).and_return(true)
            call_method
          end
          describe 'the SQL for updating the global flags' do
            it 'UPDATEs the the WEB_ADM.WEB_DATA_FLAGS table' do
              matcher = Regexp.new(/\A\s*UPDATE.*\s+WEB_ADM.WEB_DATA_FLAGS\s+/im)
              expect(disabled_reports_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
            it 'SETs the WEB_FLAG_VALUE to `Y` if the `visible` attribute of the passed flag hash is true' do
              web_flag[:visible] = true
              allow(disabled_reports_module).to receive(:quote).and_call_original
              matcher = Regexp.new(/\A\s*UPDATE.*\s+SET\s+WEB_FLAG_VALUE\s*=\s*'Y'\s+/im)
              expect(disabled_reports_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
            it 'SETs the WEB_FLAG_VALUE to `N` if the `visible` attribute of the passed flag hash is false' do
              web_flag[:visible] = false
              allow(disabled_reports_module).to receive(:quote).and_call_original
              matcher = Regexp.new(/\A\s*UPDATE.*\s+SET\s+WEB_FLAG_VALUE\s*=\s*'N'\s+/im)
              expect(disabled_reports_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
            it 'quotes the `web_flag_id` of the passed flag hash' do
              expect(disabled_reports_module).to receive(:quote).with(web_flag[:web_flag_id]).and_return(web_flag[:web_flag_id])
              call_method
            end
            it 'updates rows WHERE the WEB_FLAG_ID is equal to the quoted `web_flag_id` of the passed flag hash' do
              allow(disabled_reports_module).to receive(:quote).with(web_flag[:web_flag_id]).and_return(web_flag[:web_flag_id])
              matcher = Regexp.new(/\A\s*UPDATE.*\s+SET.*\s+WHERE\s+WEB_FLAG_ID\s*=\s*#{web_flag[:web_flag_id]}\s*.*\z/im)
              expect(disabled_reports_module).to receive(:execute_sql).with(anything, matcher).and_return(true)
              call_method
            end
          end
          it 'raises an error containing the `web_flag_id` if `execute_sql` returns nil' do
            allow(disabled_reports_module).to receive(:execute_sql)
            expect{call_method}.to raise_error(MAPI::Shared::Errors::SQLError, "Failed to update data visibility flag for web flag with id: #{web_flag[:web_flag_id]}")
          end
          it 'returns `true` if `execute_sql` does not return nil' do
            expect(call_method).to be true
          end
        end
      end
      context 'when `should_fake?` returns true' do
        before { allow(disabled_reports_module).to receive(:should_fake?).and_return(true) }

        it 'returns `true`' do
          expect(call_method).to be true
        end
      end
    end

    describe '`disabled_ids_for_member`' do
      let(:member_id) { rand(1000..9999) }
      let(:disabled_member_ids) { Array.new(4){rand(1000..9999)}.uniq }
      let(:member_string_array_result) { disabled_member_ids.collect{ |id| id.to_s} }
      let(:call_method) { disabled_reports_module.disabled_ids_for_member(app, member_id) }
      before { allow(disabled_reports_module).to receive(:should_fake?).and_return(true) }

      it 'calls `should_fake?` with the app' do
        expect(disabled_reports_module).to receive(:should_fake?).with(app).and_return(true)
        call_method
      end
      context 'when `should_fake?` returns false' do
        before { allow(disabled_reports_module).to receive(:should_fake?).and_return(false) }

        it 'calls `fetch_objects` with the logger from the app' do
          expect(disabled_reports_module).to receive(:fetch_objects).with(app.logger, anything).and_return([])
          call_method
        end
        describe 'the SQL for fetching the disabled flags for the member' do
          it 'SELECTs the WEB_FLAG_ID' do
            matcher = Regexp.new(/\A\s*SELECT.*\s+WEB_FLAG_ID\s+/im)
            expect(disabled_reports_module).to receive(:fetch_objects).with(anything, matcher).and_return([])
            call_method
          end
          it 'selects FROM the WEB_ADM.WEB_DATA_FLAGS table' do
            matcher = Regexp.new(/\A\s*SELECT.*\s+FROM\s+WEB_ADM.WEB_DATA_FLAGS_BY_INSTITUTIONS\s+/im)
            expect(disabled_reports_module).to receive(:fetch_objects).with(anything, matcher).and_return([])
            call_method
          end
          it 'selects rows WHERE the WEB_FHLB_ID is equal to the member_id' do
            matcher = Regexp.new(/\A\s*SELECT.*\s+FROM.*\s+WHERE\s+WEB_FHLB_ID\s*=\s*#{member_id}\s*.*\z/im)
            expect(disabled_reports_module).to receive(:fetch_objects).with(anything, matcher).and_return([])
            call_method
          end
        end
        it 'returns the result of fetching the member disabled flags as an array of integers' do
          allow(disabled_reports_module).to receive(:fetch_objects).and_return(member_string_array_result)
          expect(call_method).to eq(disabled_member_ids)
        end
      end
      context 'when `should_fake?` returns true' do
        before { allow(disabled_reports_module).to receive(:should_fake?).and_return(true) }

        it 'calls `fake` with `report_availability_for_member`' do
          expect(disabled_reports_module).to receive(:fake).and_return([])
          call_method
        end
        it 'returns the result of fetching the member disabled flags as an array of integers' do
          allow(disabled_reports_module).to receive(:fake).and_return(member_string_array_result)
          expect(call_method).to eq(disabled_member_ids)
        end
      end
    end
  end
end
