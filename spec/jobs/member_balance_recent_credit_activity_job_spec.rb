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

  it 'combines the array returned by` MemberBalanceService#todays_credit_activity` with the one returned by `MemberBalanceService#historic_credit_activity`' do
    allow(MemberBalanceService).to receive(:new).and_return(service_instance)
    expect(run_job).to eq(todays_credit_activity + historic_credit_activity)
  end
end
