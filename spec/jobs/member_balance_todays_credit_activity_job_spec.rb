require 'rails_helper'

RSpec.describe MemberBalanceTodaysCreditActivityJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:run_job) { subject.perform(member_id) }
  let(:results) { double('results') }

  it 'should call `MemberBalanceService#todays_credit_activity`' do
    expect_any_instance_of(MemberBalanceService).to receive(:todays_credit_activity).and_return(results)
    run_job
  end
  [:development, :test].each do |env|
    it "should sleep for 3s in the #{env} environment" do
      allow(Rails.env).to receive(:production?).and_return(false)
      expect(subject).to receive(:sleep).with(3)
      run_job
    end
  end
  it 'should not sleep in the production environment' do
    allow(Rails.env).to receive(:production?).and_return(true)
    expect(subject).not_to receive(:sleep)
    run_job
  end
end
