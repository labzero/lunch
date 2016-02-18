require 'rails_helper'

RSpec.describe WebAdminPolicy, :type => :policy do
  let(:user) { double(User, id: double('User ID')) }
  let(:request) { ActionDispatch::TestRequest.new }

  describe '`show?` method' do
    subject { WebAdminPolicy.new(user, request) }

    context 'for an admin' do
      before do
        allow(user).to receive(:roles).and_return([User::Roles::ADMIN])
      end
      it { should permit_action(:show) }
    end

    context 'for a non-admin' do
      before do
        allow(user).to receive(:roles).and_return([])
      end
      it { should_not permit_action(:show) }
    end

    context 'for a nont existant user' do
      subject { WebAdminPolicy.new(nil, request) }

      it { should_not permit_action(:show) }      
    end
  end
end