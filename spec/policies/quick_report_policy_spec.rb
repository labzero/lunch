require 'rails_helper'

RSpec.describe QuickReportPolicy, type: :policy do
  let(:member) { Member.new(SecureRandom.hex) }
  let(:quick_report_set) { double(QuickReportSet, member_id: SecureRandom.hex) }
  let(:quick_report) { double(QuickReport, quick_report_set: quick_report_set) }
  subject { described_class.new(member, quick_report) }

  describe '`download?`' do
    context 'when the quick report is not owned by the member' do
      it { should_not permit_action(:download) }
    end
    context 'when the quick report is owned by the member' do
      before do
        allow(quick_report_set).to receive(:member_id).and_return(member.member_id)
      end
      it { should permit_action(:download) }
    end
  end
end