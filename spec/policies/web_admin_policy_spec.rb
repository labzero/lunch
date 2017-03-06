require 'rails_helper'

RSpec.describe WebAdminPolicy, :type => :policy do
  let(:user) { instance_double(User, id: double('User ID')) }
  let(:request) { ActionDispatch::TestRequest.new }

  describe '`show?` method' do
    subject { WebAdminPolicy.new(user, request) }

    context 'for a internal user' do
      before do
        allow(user).to receive(:intranet_user?).and_return(true)
      end
      it { should permit_action(:show) }
    end

    context 'for an external user' do
      before do
        allow(user).to receive(:intranet_user?).and_return(false)
      end
      it { should_not permit_action(:show) }
    end

    context 'for a non-existant user' do
      subject { WebAdminPolicy.new(nil, request) }

      it { should_not permit_action(:show) }      
    end
  end

  describe '`edit_features?` method' do
    subject { WebAdminPolicy.new(user, request) }

    context 'for an admin' do
      before do
        allow(user).to receive(:roles).and_return([User::Roles::ADMIN])
      end
      it { should permit_action(:edit_features) }
    end

    context 'for a non-admin' do
      before do
        allow(user).to receive(:roles).and_return([])
      end
      it { should_not permit_action(:edit_features) }
    end

    context 'for a non-existant user' do
      subject { WebAdminPolicy.new(nil, request) }

      it { should_not permit_action(:edit_features) }      
    end
  end
end