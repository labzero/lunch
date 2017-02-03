require 'rails_helper'

RSpec.describe LettersOfCreditPolicy, :type => :policy do
  let(:user) { double(User, id: double('User ID'), member: nil) }

  describe '`request?` method' do
    subject { LettersOfCreditPolicy.new(user, :letter_of_credit) }

    context 'for an intranet user' do
      before { allow(user).to receive(:intranet_user?).and_return(true) }

      it { should permit_action(:request) }
    end
    context 'for a non-intranet user' do
      before { allow(user).to receive(:intranet_user?).and_return(false) }

      context 'for a signer' do
        before do
          allow(user).to receive(:roles).and_return([User::Roles::ADVANCE_SIGNER])
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

  describe '`execute?` method' do
    subject { LettersOfCreditPolicy.new(user, :letter_of_credit) }

    context 'for an intranet user' do
      before { allow(user).to receive(:intranet_user?).and_return(true) }

      it { should_not permit_action(:execute) }
    end
    context 'for a non-intranet user' do
      before { allow(user).to receive(:intranet_user?).and_return(false) }

      context 'for a signer' do
        before do
          allow(user).to receive(:roles).and_return([User::Roles::ADVANCE_SIGNER])
        end
        it { should permit_action(:execute) }
      end

      context 'for a non-signer' do
        before do
          allow(user).to receive(:roles).and_return([])
        end
        it { should_not permit_action(:execute) }
      end
    end
  end
end