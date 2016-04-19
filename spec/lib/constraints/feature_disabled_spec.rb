require 'rails_helper'

RSpec.describe Constraints::FeatureDisabled do
  let(:feature) { double('A Feature') }
  let(:request) { ActionDispatch::TestRequest.new }
  subject { described_class.new(feature) }
  describe '`matches?`' do
    let(:user) { double(User) }
    let(:warden) { double(Warden::Proxy, user: user)}
    let(:call_method) { subject.matches?(request) }

    before do
      allow(request.env).to receive(:[]).with('warden').and_return(warden)
      allow(subject).to receive(:feature_enabled?)
    end
    it 'returns false if the feature is enabled for the current user' do
      expect(subject).to receive(:feature_enabled?).with(feature, user).and_return(true)
      expect(call_method).to eq(false)
    end
    it 'returns true if the feature is disabled for the current user' do
      expect(subject).to receive(:feature_enabled?).with(feature, user).and_return(false)
      expect(call_method).to eq(true)
    end
  end
end