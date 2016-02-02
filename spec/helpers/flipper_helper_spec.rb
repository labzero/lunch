require 'rails_helper'

RSpec.describe FlipperHelper, type: :helper do
  describe '`feature_enabled?` method' do
    let(:feature) { double(Flipper::Feature, enabled?: false) }
    let(:feature_name) { SecureRandom.hex }
    let(:user) { double(User) }
    let(:member_id) { double('A Member ID') }
    let(:call_method) { helper.feature_enabled?(feature_name, user) }
    let(:flipper) { Rails.application.flipper }

    before do
      allow(flipper).to receive(:[]).with(feature_name.to_sym).and_return(feature)
      def helper.current_member_id
      end
      allow(helper).to receive(:current_member_id).and_return(member_id)
    end

    it 'looks up the feature in Flipper' do
      expect(flipper).to receive(:[]).with(feature_name.to_sym).and_return(feature)
      call_method
    end
    it 'gets the user from the session if none is provided' do
      expect(helper).to receive(:current_user)
      helper.feature_enabled?(feature_name)
    end
    it 'checks if the feature is enabled for a given user' do
      expect(feature).to receive(:enabled?).with(user)
      call_method
    end
    it 'checks if the feature has been enabled for a given users member institution' do
      expect(feature).to receive(:enabled?).with(kind_of(Member))
      call_method
    end
    it 'fetches the member id from the session if present' do
      expect(helper).to receive(:current_member_id)
      call_method
    end
    it 'fetches the member id from the user if one was not found in the session' do
      allow(helper).to receive(:current_member_id).and_return(nil)
      expect(user).to receive(:member_id)
      call_method
    end
    it 'turns the member id into a Member' do
      expect(Member).to receive(:new).with(member_id)
      call_method
    end
    it 'returns true if the feature is enabled for the user but not their member institution' do
      allow(feature).to receive(:enabled?).with(user).and_return(true)
      allow(feature).to receive(:enabled?).with(kind_of(Member)).and_return(false)
      expect(call_method).to be(true)
    end
    it 'returns true if the feature is enabled for the member institution but not the user' do
      allow(feature).to receive(:enabled?).with(user).and_return(false)
      allow(feature).to receive(:enabled?).with(kind_of(Member)).and_return(true)
      expect(call_method).to be(true)
    end
    it 'returns true if the feature is enabled for both the user and the member institution' do
      allow(feature).to receive(:enabled?).with(user).and_return(true)
      allow(feature).to receive(:enabled?).with(kind_of(Member)).and_return(true)
      expect(call_method).to be(true)
    end
    it 'returns false if the feature is not enabled for both the user and the member institution' do
      allow(feature).to receive(:enabled?).with(user).and_return(false)
      allow(feature).to receive(:enabled?).with(kind_of(Member)).and_return(false)
      expect(call_method).to be(false)
    end
  end
end