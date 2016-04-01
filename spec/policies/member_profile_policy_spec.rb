require 'rails_helper'

RSpec.describe MemberProfilePolicy, :type => :policy do
  let(:user) { double(User, id: double('User ID')) }
  let(:request) { ActionDispatch::TestRequest.new }

  describe '`show?` method' do
    subject { MemberProfilePolicy.new(user, request) }

    context 'for an extended info user' do
      before do
        allow(user).to receive(:roles).and_return([User::Roles::USER_WITH_EXTENDED_INFO_ACCESS])
      end
      it { should permit_action(:show) }
    end

    context 'for a regular user' do
      before do
        allow(user).to receive(:roles).and_return([])
      end
      it { should_not permit_action(:show) }
    end

    context 'for a non existant user' do
      subject { MemberProfilePolicy.new(nil, request) }

      it { should_not permit_action(:show) }      
    end
  end
end