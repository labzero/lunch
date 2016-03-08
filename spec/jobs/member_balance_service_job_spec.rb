require 'rails_helper'

RSpec.describe MemberBalanceServiceJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:uuid) { double('uuid') }
  let(:request) { double('request', uuid: nil) }
  let(:member_balance_service) { double('member balance service', send: nil) }
  let(:service_value) { double('value returned from a service') }
  let(:method) { double('member balance service method') }
  let(:run_job) { subject.perform(member_id, method) }

  before do
    allow(MemberBalanceService).to receive(:new).and_return(member_balance_service)
    allow(ActionDispatch::TestRequest).to receive(:new).and_return(request)
    allow(method).to receive(:to_sym).and_return(method)
  end

  it 'creates a TestRequest with the supplied uuid' do
    expect(ActionDispatch::TestRequest).to receive(:new).with({'action_dispatch.request_id' => uuid})
    subject.perform(member_id, method, uuid)
  end
  it 'creates a TestRequest with the job_id if no uuid is supplied' do
    expect(ActionDispatch::TestRequest).to receive(:new).with({'action_dispatch.request_id' => subject.job_id})
    run_job
  end
  it 'creates a MemberBalanceService instance with the member id' do
    expect(MemberBalanceService).to receive(:new).with(member_id, anything).and_return(member_balance_service)
    run_job
  end
  it 'creates a MemberBalanceService instance with the request' do
    expect(MemberBalanceService).to receive(:new).with(anything, request).and_return(member_balance_service)
    run_job
  end
  it 'sends the method call to the member balance service instance' do
    expect(member_balance_service).to receive(:send).with(method)
    run_job
  end
  it 'sends all supplied args to the member balance service instance' do
    args = [double('arg_1'), double('arg_2'), double('arg_3')]
    expect(member_balance_service).to receive(:send).with(anything, *args)
    subject.perform(member_id, method, nil, *args)
  end
end