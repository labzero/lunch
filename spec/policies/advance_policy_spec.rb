require 'rails_helper'

RSpec.describe AdvancePolicy, :type => :policy do
  subject { AdvancePolicy.new(user, :advance) }

  describe '`show?` method' do
    let(:user) { double('user') }

    context 'for a signer' do
      before do
        allow(user).to receive(:roles).and_return([User::Roles::ADVANCE_SIGNER])
      end
      it { should permit_action(:show) }
    end

    context 'for a non-signer' do
      before do
        allow(user).to receive(:roles).and_return([])
      end
      it { should_not permit_action(:show) }
    end
  end
end