require 'spec_helper'

describe MAPI::ServiceApp do

  before do
    header 'Authorization', "Token token=\"#{ENV['MAPI_SECRET_TOKEN']}\""
  end

  describe 'member disabled reports' do
    let(:disabled_reports) { get "/member/#{MEMBER_ID}/disabled_reports"; JSON.parse(last_response.body) }

    it 'returns an array of ids for disabled reports' do
      expect(disabled_reports).to be_kind_of(Array)
    end

    describe 'in the production environment' do
      let(:global_disabled_reports_result) {double('Oracle Result Set', fetch: nil)}
      let(:member_disabled_reports_result) {double('Oracle Result Set', fetch: nil)}

      before do
        expect(MAPI::ServiceApp).to receive(:environment).at_least(1).and_return(:production)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(global_disabled_reports_result)
        expect(ActiveRecord::Base.connection).to receive(:execute).with(kind_of(String)).and_return(member_disabled_reports_result)
      end

      describe 'with reports flagged as disabled' do
        let(:global_disabled_report_ids) {[[5], [6], [7], [8], nil]}
        let(:member_disabled_report_ids) {[[1], [6], [7], [10], nil]}
        before do
          allow(global_disabled_reports_result).to receive(:fetch).and_return(*global_disabled_report_ids)
          allow(member_disabled_reports_result).to receive(:fetch).and_return(*member_disabled_report_ids)
        end

        it 'returns an array of report_ids that include those that have been flagged as disabled for all users' do
          global_disabled_report_ids.each do |row|
            expect(disabled_reports).to include(row[0]) unless row.nil?
          end
        end
        it 'returns an array of report_ids that include those that have been flagged as disabled for only this user' do
          member_disabled_report_ids.each do |row|
            expect(disabled_reports).to include(row[0]) unless row.nil?
          end
        end
        it 'discards any duplicate report_ids after combining global disabled flags and member disabled flags' do
          expect(disabled_reports).to eq((global_disabled_report_ids.flatten + member_disabled_report_ids.flatten).uniq.compact)
        end
      end

      describe 'with no reports flagged as disabled' do
        before do
          allow(global_disabled_reports_result).to receive(:fetch).and_return(nil)
          allow(member_disabled_reports_result).to receive(:fetch).and_return(nil)
        end
        it 'returns an empty array if no report_ids have been flagged as disabled globally or for the member' do
          expect(disabled_reports).to eq([])
        end
      end
    end
  end
end
