require 'rails_helper'

RSpec.describe AccessManagerPolicy, :type => :policy do
  let(:user) { double('user', id: 1) }
  let(:resource) { double('resource user', id: 2) }
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
      it { should_not permit_action(:create) }
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
    end
  end
end