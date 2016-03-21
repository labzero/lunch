require 'rails_helper'

RSpec.describe ReportCurrentPriceIndicationsJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:uuid) { double('uuid') }
  let(:request) { double('request', uuid: nil) }
  let(:run_job) { subject.perform(member_id) }
  let(:rate_service) { double('rate service', current_price_indications: nil) }
  let(:member_balance_service) { double('member balance service', settlement_transaction_rate: nil) }
  let(:service_value) { double('value returned from a service') }

  before do
    allow(RatesService).to receive(:new).and_return(rate_service)
    allow(MemberBalanceService).to receive(:new).and_return(member_balance_service)
    allow(ActionDispatch::TestRequest).to receive(:new).and_return(request)
  end

  it 'creates a TestRequest with the supplied uuid' do
    expect(ActionDispatch::TestRequest).to receive(:new).with({'action_dispatch.request_id' => uuid})
    subject.perform(member_id, uuid)
  end
  it 'creates a TestRequest with the job_id if no uuid is supplied' do
    expect(ActionDispatch::TestRequest).to receive(:new).with({'action_dispatch.request_id' => subject.job_id})
    run_job
  end
  it 'creates a RateService instance with the request' do
    expect(RatesService).to receive(:new).with(request).and_return(rate_service)
    run_job
  end
  it 'creates a MemberBalanceService instance with the member id and request' do
    expect(MemberBalanceService).to receive(:new).with(member_id, request).and_return(member_balance_service)
    run_job
  end
  [['standard', 'vrc'], ['sbc', 'vrc'], ['standard', 'frc'], ['sbc', 'frc'], ['standard', 'arc'], ['sbc', 'arc']].each do |collateral, credit|
    key = :"#{collateral}_#{credit}_data"
    it "returns a hash with a `#{key}` value that is the result of calling `current_price_indications` with `#{collateral}` and `#{credit}`" do
      allow(rate_service).to receive(:current_price_indications).with(collateral, credit).and_return(service_value)
      expect(run_job[key]).to eq(service_value)
    end
  end
  it 'returns a hash with a `sta_data` value that is the result of calling `settlement_transaction_rate` on the member balance instance' do
    allow(member_balance_service).to receive(:settlement_transaction_rate).and_return(service_value)
    expect(run_job[:sta_data]).to eq(service_value)
  end
end
