require 'rails_helper'

RSpec.describe RatesServiceJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:uuid) { double('uuid') }
  let(:request) { double('request', uuid: nil) }
  let(:rates_service) { double('rates service', send: nil) }
  let(:service_value) { double('value returned from a service') }
  let(:method) { double('rates service method') }
  let(:run_job) { subject.perform(method) }

  before do
    allow(RatesService).to receive(:new).and_return(rates_service)
    allow(ActionDispatch::TestRequest).to receive(:new).and_return(request)
    allow(method).to receive(:to_sym).and_return(method)
  end

  it 'creates a TestRequest with the supplied uuid' do
    expect(ActionDispatch::TestRequest).to receive(:new).with({'action_dispatch.request_id' => uuid})
    subject.perform(method, uuid)
  end
  it 'creates a TestRequest with the job_id if no uuid is supplied' do
    expect(ActionDispatch::TestRequest).to receive(:new).with({'action_dispatch.request_id' => subject.job_id})
    run_job
  end
  it 'creates a RatesService instance with the request' do
    expect(RatesService).to receive(:new).with(request).and_return(rates_service)
    run_job
  end
  it 'sends the method call to the rates service instance' do
    expect(rates_service).to receive(:send).with(method)
    run_job
  end
  it 'sends all supplied args to the rates service instance' do
    args = [double('arg_1'), double('arg_2'), double('arg_3')]
    expect(rates_service).to receive(:send).with(anything, *args)
    subject.perform(method, nil, *args)
  end
end