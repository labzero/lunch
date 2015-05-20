require 'rails_helper'

RSpec.describe AccessManagerPolicy, :type => :policy do
  subject { AccessManagerPolicy.new(user, :access_manager) }

  describe '`show?` method' do
    let(:user) { double('user') }

    context 'for an access manager' do
      before do
        allow(user).to receive(:roles).and_return([User::Roles::ACCESS_MANAGER])
      end
      it { should permit_action(:show) }
    end

    context 'for a non-access manager' do
      before do
        allow(user).to receive(:roles).and_return([])
      end
      it { should_not permit_action(:show) }
    end
  end
end