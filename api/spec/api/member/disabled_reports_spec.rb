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
