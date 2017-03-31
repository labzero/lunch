require 'rails_helper'

RSpec.describe AccountSummaryJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:run_job) { subject.perform(member_id) }
  let(:uuid) { double('uuid') }
  let(:members_service_instance) { instance_double(MembersService) }
  let(:member_balance_service_instance) { instance_double(MemberBalanceService) }
  let(:member_profile) { instance_double(Hash) }
  let(:member_details) { instance_double(Hash) }
  let(:test_request) { ActionDispatch::TestRequest.new({'action_dispatch.request_id' => uuid}) }

  it_behaves_like 'a job that makes service calls', MemberBalanceService, :profile

  before do
    allow(ActionDispatch::TestRequest).to receive(:new).with(anything).and_return(test_request)
    allow(MemberBalanceService).to receive(:new).with(member_id, test_request).and_return(member_balance_service_instance)
    allow(member_balance_service_instance).to receive(:profile).and_return(member_profile)
    allow(MembersService).to receive(:new).with(test_request).and_return(members_service_instance)
    allow(members_service_instance).to receive(:member).with(member_id).and_return(member_details)
  end

  it "calls `member` on `MembersService`" do
    expect(members_service_instance).to receive(:member).with(member_id)
    run_job
  end

  it "creates a new instance of `MembersService` with an instance of `ActionDispatch::TestRequest`" do
    expect(MembersService).to receive(:new).with(test_request)
    run_job
  end

  it 'creates an instance of `TestRequest` using the uuid if one is provided' do
     expect(ActionDispatch::TestRequest).to receive(:new).with({'action_dispatch.request_id' => uuid})
     subject.perform(member_id, uuid)
   end

  it 'creates an instance of `TestRequest` with a nil uuid if one is not provided' do
    expect(ActionDispatch::TestRequest).to receive(:new).with({'action_dispatch.request_id' => nil})
    run_job
  end
end