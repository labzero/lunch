require 'rails_helper'

RSpec.describe MortgagePolicy, :type => :policy do
  let(:user) { instance_double(User, id: double('User ID'), member: nil) }
  let(:request) { ActionDispatch::TestRequest.new }

  describe '`request?` method' do
    subject { MortgagePolicy.new(user, request) }

    context 'for an intranet user' do
      before { allow(user).to receive(:intranet_user?).and_return(true) }

      it { should permit_action(:request) }
    end
    context 'for a non-intranet user' do
      before { allow(user).to receive(:intranet_user?).and_return(false) }

      context 'for a signer' do
        before do
          allow(user).to receive(:roles).and_return([User::Roles::COLLATERAL_SIGNER])
        end
        it { should permit_action(:request) }
      end

      context 'for a non-signer' do
        before do
          allow(user).to receive(:roles).and_return([])
        end
        it { should_not permit_action(:request) }
      end
    end
  end
end