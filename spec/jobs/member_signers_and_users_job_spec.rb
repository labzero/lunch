require 'rails_helper'

RSpec.describe MemberSignersAndUsersJob, type: :job do
  let(:member_id) { double('A Member ID') }
  let(:run_job) { subject.perform(member_id) }
  let(:results) { double('results') }

  it 'should call `MembersService#signers_and_users`' do
    expect_any_instance_of(MembersService).to receive(:signers_and_users).with(member_id).and_return(results)
    run_job
  end
end
