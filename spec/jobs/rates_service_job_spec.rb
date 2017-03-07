require 'rails_helper'

RSpec.describe RatesServiceJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:uuid) { double('uuid') }
  let(:user_id) { double('user_id') }
  let(:request) { double('request', uuid: nil) }
  let(:rates_service) { instance_double(RatesService, send: nil, :connection_request_uuid= => uuid, :connection_user_id= => user_id) }
  let(:service_value) { double('value returned from a service') }
  let(:method) { double('rates service method') }
  let(:run_job) { subject.perform(method) }

  before do
    allow(RatesService).to receive(:new).and_return(rates_service)
    allow(ActionDispatch::TestRequest).to receive(:new).and_return(request)
    allow(method).to receive(:to_sym).and_return(method)
  end

  it 'assigns the supplied `uuid` to the service instance' do
    expect(rates_service).to receive(:connection_request_uuid=).with(uuid)
    subject.perform(method, uuid)
  end
  it 'assigns the `job_id` to the service instance if no `uuid` is provided' do
    expect(rates_service).to receive(:connection_request_uuid=).with(subject.job_id)
    run_job
  end
  it 'assigns the supplied `user_id` to the service instance' do
    expect(rates_service).to receive(:connection_user_id=).with(user_id)
    subject.perform(method, uuid, user_id)
  end
  it 'assigns nil to the serice instance `user_id` if no `user_id` is provided' do
    expect(rates_service).to receive(:connection_user_id=).with(nil)
    subject.perform(method, uuid)
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
    subject.perform(method, nil, nil, *args)
  end
end