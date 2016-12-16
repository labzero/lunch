require 'rails_helper'

RSpec.describe MemberBalanceRecentCreditActivityJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:todays_credit_activity) {[
    instance_double(Hash),
    instance_double(Hash)
  ]}
  let(:historic_credit_activity) {[
    instance_double(Hash),
    instance_double(Hash)
  ]}
  let(:service_instance) { instance_double(MemberBalanceService, todays_credit_activity: todays_credit_activity, historic_credit_activity: historic_credit_activity) }
  let(:run_job) { subject.perform(member_id) }

  it_behaves_like 'a job that makes service calls', MemberBalanceService, [:todays_credit_activity, :historic_credit_activity]

  shared_examples 'fails gracefully' do
    it 'returns nil' do
      expect(run_job).to be_nil
    end
    it 'marks the job as failed' do
      run_job
      expect(subject.job_status).to be_failed
    end
    it 'does not raise an error' do
      expect{run_job}.to_not raise_error
    end
  end

  before do
    allow(MemberBalanceService).to receive(:new).and_return(service_instance)
  end

  it 'combines the array returned by `MemberBalanceService#todays_credit_activity` with the one returned by `MemberBalanceService#historic_credit_activity`' do
    expect(run_job).to eq(todays_credit_activity + historic_credit_activity)
  end

  describe 'when `MemberBalanceService#todays_credit_activity` returns nil' do
    before do
      allow(service_instance).to receive(:todays_credit_activity).and_return(nil)
    end
    include_examples 'fails gracefully'
  end

  describe 'when `MemberBalanceService#historic_credit_activity` returns nil' do
    before do
      allow(service_instance).to receive(:historic_credit_activity).and_return(nil)
    end
    include_examples 'fails gracefully'
  end

  describe 'when `MemberBalanceService#historic_credit_activity` and `MemberBalanceService#todays_credit_activity` both return nil' do
    before do
      allow(service_instance).to receive(:historic_credit_activity).and_return(nil)
      allow(service_instance).to receive(:todays_credit_activity).and_return(nil)
    end
    include_examples 'fails gracefully'
  end
end
