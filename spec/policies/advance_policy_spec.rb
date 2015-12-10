require 'rails_helper'

RSpec.describe AdvancePolicy, :type => :policy do
  let(:user) { double(User, id: double('User ID')) }
  let(:advance_request) { double(AdvanceRequest) }

  describe '`show?` method' do
    subject { AdvancePolicy.new(user, :advance) }

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

  describe '`modify?` method' do
    subject { AdvancePolicy.new(user, advance_request) }
    before do
      allow(advance_request).to receive(:owners).and_return(Set.new)
    end
    it 'returns true if the user is an owner of the advance' do
      advance_request.owners.add(user.id)
      expect(subject).to permit_action(:modify)
    end
    it 'returns false if the user is not an owner of the advance' do
      expect(subject).to_not permit_action(:modify)
    end
  end
end