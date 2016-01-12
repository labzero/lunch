require 'rails_helper'

RSpec.describe MemberBalanceProfileJob, type: :job do
  let(:member_id) { double('A Member ID') }
  it_behaves_like 'a job that makes service calls', MemberBalanceService, :profile

  it 'returns an empty hash if the profile endpoint returns nil' do
    allow(MemberBalanceService).to receive(:new).and_return(double('service instance', profile: nil))
    expect(subject.perform(member_id)).to eq({})
  end
end