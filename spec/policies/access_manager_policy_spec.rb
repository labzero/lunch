require 'rails_helper'

RSpec.describe AccessManagerPolicy, :type => :policy do
  let(:user) { instance_double(User, id: 1, intranet_user?: false) }
  let(:resource) { instance_double(User, id: 2) }
  subject { AccessManagerPolicy.new(user, resource) }

  describe '`show?` method' do

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

      context 'for an internal user' do
        before do
          allow(user).to receive(:intranet_user?).and_return(true)
        end
        it { should permit_action(:show) }
      end
    end
  end

  describe '`create?` method' do

    context 'for an access manager' do
      before do
        allow(user).to receive(:roles).and_return([User::Roles::ACCESS_MANAGER])
      end
      it { should permit_action(:create) }
    end

    context 'for a non-access manager' do
      before do
        allow(user).to receive(:roles).and_return([])
      end
      it {  permit_action(:create) }

      context 'for an internal user' do
        before do
          allow(user).to receive(:intranet_user?).and_return(true)
        end
        it { should_not permit_action(:create) }
      end
    end
  end

  describe '`reset_password?` method' do

    context 'for an access manager' do
      before do
        allow(user).to receive(:roles).and_return([User::Roles::ACCESS_MANAGER])
      end
      it { should permit_action(:reset_password) }
    end

    context 'for a non-access manager' do
      before do
        allow(user).to receive(:roles).and_return([])
      end
      it { should_not permit_action(:reset_password) }

      context 'for an internal user' do
        before do
          allow(user).to receive(:intranet_user?).and_return(true)
        end
        it { should_not permit_action(:reset_password) }
      end
    end
  end

  describe '`edit?` method' do

    context 'for an access manager' do
      before do
        allow(user).to receive(:roles).and_return([User::Roles::ACCESS_MANAGER])
      end
      it { should permit_action(:edit) }
    end

    context 'for a non-access manager' do
      before do
        allow(user).to receive(:roles).and_return([])
      end
      it { should_not permit_action(:edit) }

      context 'for an internal user' do
        before do
          allow(user).to receive(:intranet_user?).and_return(true)
        end
        it { should_not permit_action(:edit) }
      end
    end
  end

  describe '`lock?` method' do

    context 'for an access manager' do
      before do
        allow(user).to receive(:roles).and_return([User::Roles::ACCESS_MANAGER])
      end
      it { should permit_action(:lock) }
      context 'locking themselves' do
        before do
          allow(user).to receive(:id).and_return(resource.id)
        end
        it { should_not permit_action(:lock) }
      end
    end

    context 'for a non-access manager' do
      before do
        allow(user).to receive(:roles).and_return([])
      end
      it { should_not permit_action(:lock) }

      context 'for an internal user' do
        before do
          allow(user).to receive(:intranet_user?).and_return(true)
        end
        it { should_not permit_action(:lock) }
      end
    end
  end

  describe '`delete?` method' do

    context 'for an access manager' do
      before do
        allow(user).to receive(:roles).and_return([User::Roles::ACCESS_MANAGER])
      end
      it { should permit_action(:delete) }
      context 'locking themselves' do
        before do
          allow(user).to receive(:id).and_return(resource.id)
        end
        it { should_not permit_action(:delete) }
      end
    end

    context 'for a non-access manager' do
      before do
        allow(user).to receive(:roles).and_return([])
      end
      it { should_not permit_action(:delete) }

      context 'for an internal user' do
        before do
          allow(user).to receive(:intranet_user?).and_return(true)
        end
        it { should_not permit_action(:delete) }
      end
    end
  end
end