require 'rails_helper'

describe UserPolicy, type: :policy do
  let(:request) { double('A Request') }
  let(:user) { double('A User') }
  subject { described_class.new(user, request) }

  describe '`change_password?` method' do
    context 'for an non-intranet user' do
      before do
        allow(user).to receive(:intranet_user?).and_return(false)
      end
      it { should permit_action(:change_password) }
    end

    context 'for an intranet user' do
      before do
        allow(user).to receive(:intranet_user?).and_return(true)
      end
      it { should_not permit_action(:change_password) }
    end
  end
end