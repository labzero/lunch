require 'rails_helper'

RSpec.describe QuickReportsController, type: :controller do
  login_user
  quick_report_id = rand(1..100).to_s
  let(:quick_report) { QuickReport.new }
  let(:quick_report_id) { quick_report_id }
  before do
    allow(QuickReport).to receive(:find).with(quick_report_id).and_return(quick_report)
  end

  describe 'GET download' do
    allow_policy_resource(:quick_report, :download?)
    let(:make_request) { get :download, id: quick_report_id }

    it_behaves_like 'a user required action', :get, :download, id: quick_report_id
    context do
      deny_policy_resource(:quick_report, :download?)
      it 'does not permit the download if the policy denies it' do
        expect{make_request}.to raise_error(Pundit::NotAuthorizedError)
      end
    end
    it 'raises an error if the QuickReport does not have a report attached' do
      expect{make_request}.to raise_error(ActiveRecord::RecordNotFound)
    end
    it 'sends the report to the user' do
      report = double(Paperclip::Attachment, original_filename: SecureRandom.hex, content_type: SecureRandom.hex, file?: true)
      allow(quick_report).to receive(:report_as_string).and_return(SecureRandom.hex)
      allow(quick_report).to receive(:report).and_return(report)
      expect(controller).to receive(:send_data).with(quick_report.report_as_string, {
        filename: report.original_filename,
        type: report.content_type,
        disposition: 'attachment'
      }).and_call_original
      make_request
    end
  end

  describe '`pundit_user` instance method' do
    let(:call_method) { controller.pundit_user }
    it 'returns the `current_user` if there is no `current_member_id`' do
      expect(call_method).to be(controller.current_user)
    end
    describe 'if `current_member_id` is present' do
      let(:member_id) { double('A Member ID') }
      before do
        allow(controller).to receive(:current_member_id).and_return(member_id)
      end
      it 'returns a Member' do
        expect(call_method).to be_kind_of(Member)
      end
      it 'has the `current_member_id` as its `member_id`' do
        expect(call_method.member_id).to be(member_id)
      end
    end
  end

end
