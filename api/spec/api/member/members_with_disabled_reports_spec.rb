require 'spec_helper'

describe MAPI::ServiceApp do
  let(:app) { double(MAPI::ServiceApp, logger: double('logger')) }
  let(:members_with_disabled_reports_module) { MAPI::Services::Member::MembersWithDisabledReports }

  describe 'class methods' do
    describe '`members_with_disabled_reports`' do
        let(:member_list) { [{"FHLB_ID": "1", "MEMBER_NAME": "Old McDonald's Leanding Window"},
                             {"FHLB_ID": "2", "MEMBER_NAME": "Bobby's Payday Loans"},
                             {"FHLB_ID": "3", "MEMBER_NAME": "Irish Bank"}] }
      let(:member_array_result) {  member_list.collect do |member|
        member = member.with_indifferent_access
          {
            "FHLB_ID": member['FHLB_ID'],
            "MEMBER_NAME": member['MEMBER_NAME']
          }
        end
      }
      let(:call_method) { members_with_disabled_reports_module.members_with_disabled_reports(app) }
      before { allow(members_with_disabled_reports_module).to receive(:should_fake?).and_return(true) }

      it 'calls `should_fake?` with the app' do
        expect(members_with_disabled_reports_module).to receive(:should_fake?).with(app).and_return(true)
        call_method
      end
      context 'when `should_fake?` returns false' do
        before { allow(members_with_disabled_reports_module).to receive(:should_fake?).and_return(false) }

        it 'calls `fetch_objects` with the logger from the app' do
          expect(members_with_disabled_reports_module).to receive(:fetch_hashes).with(app, anything).and_return([])
          call_method
        end
        describe 'the SQL for fetching the set of members with disabled reports' do
          it 'SELECTs the columns `FHLB_ID` and `MEMBER_NAME`' do
             matcher = Regexp.new(/\A\s*SELECT.*\s+FHLB_ID.*\s+CU_SHORT_NAME\s+/im)
             expect(members_with_disabled_reports_module).to receive(:fetch_hashes).with(anything, matcher).and_return([])
             call_method
          end
          it 'selects FROM an INNER JOIN of the `WEB_ADM.WEB_DATA_FLAGS_BY_INSTITUTIONS` and the `PORTFOLIOS.CUSTOMERS` tables' do
            matcher = Regexp.new(/\A\s*SELECT.*\s+FROM\s+WEB_ADM.WEB_DATA_FLAGS_BY_INSTITUTIONS\s+INNER JOIN\s+PORTFOLIOS.CUSTOMERS\s+/im)
            expect(members_with_disabled_reports_module).to receive(:fetch_hashes).with(anything, matcher).and_return([])
            call_method
          end
        end
        it 'returns the result of fetching the global disabled flags as an array of integers' do
          allow(members_with_disabled_reports_module).to receive(:fetch_hashes).and_return(member_array_result)
          expect(call_method).to eq(member_list)
        end
      end
      context 'when `should_fake?` returns true' do
        before {
          allow(members_with_disabled_reports_module).to receive(:should_fake?).and_return(true)
        }

        it 'calls `fake` with `members_with_disabled_reports`' do
          expect(members_with_disabled_reports_module).to receive(:fake).with('members_with_disabled_reports').and_return([])
          call_method
        end
        it 'returns the result of fetching all members with disabled reports, as an array of hashes' do
          expect(members_with_disabled_reports_module).to receive(:fake).with('members_with_disabled_reports').and_return(member_array_result)
          expect(call_method).to eq(member_list)
        end
      end
    end
  end
end