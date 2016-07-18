require 'rails_helper'

RSpec.describe SecurityPolicy, :type => :policy do
  let(:user) { instance_double(User) }

  describe '`authorize?` method' do
    subject { SecurityPolicy.new(user, :advance) }

    context "for a User with the `#{User::Roles::SECURITIES_SIGNER}` role" do
      before { allow(user).to receive(:roles).and_return([User::Roles::SECURITIES_SIGNER]) }
      it { should permit_action(:authorize) }
    end
    context "for a User without the `#{User::Roles::SECURITIES_SIGNER}` role" do
      before { allow(user).to receive(:roles).and_return([]) }
      it { should_not permit_action(:authorize) }
    end
  end

  describe '`delete?` method' do
    subject { SecurityPolicy.new(user, :advance) }

    context "for a User with the `#{User::Roles::SECURITIES_SIGNER}` role" do
      before { allow(user).to receive(:roles).and_return([User::Roles::SECURITIES_SIGNER]) }
      it { should permit_action(:delete) }
    end
    context "for a User without the `#{User::Roles::SECURITIES_SIGNER}` role" do
      before { allow(user).to receive(:roles).and_return([]) }
      it { should_not permit_action(:delete) }
    end
  end
end