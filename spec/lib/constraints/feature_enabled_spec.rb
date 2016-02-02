require 'rails_helper'


RSpec.describe Constraints::FeatureEnabled do
  let(:feature) { double('A Feature') }
  let(:member_id) { double('A Member ID') }
  let(:session) { {member_id: member_id}.with_indifferent_access }
  let(:request) { ActionDispatch::TestRequest.new }
  subject { described_class.new(feature) }
  describe '`initialize` method' do
    it 'assigns the supplied feature to the `feature` attribute' do
      expect(subject.feature).to eq(feature)
    end
  end
  describe '`current_member_id` method' do
    let(:call_method) { subject.current_member_id }
    before do
      Thread.current[described_class::REQUEST_KEY] = request
      allow(request).to receive(:session).and_return(session)
    end
    after do
      Thread.current[described_class::REQUEST_KEY] = nil
    end
    it 'fetches the session from the request' do
      expect(request).to receive(:session)
      call_method
    end
    it 'handles thes request not existing' do
      Thread.current[described_class::REQUEST_KEY] = nil
      expect(call_method).to be_nil
    end
    it 'returns the `member_id` entry from the session' do
      expect(call_method).to be(member_id)
    end
    it 'handles the session not existing' do
      allow(request).to receive(:session).and_return(nil)
      expect(call_method).to be_nil
    end
  end
  describe '`matches?` method' do
    let(:user) { double(User) }
    let(:warden) { double(Warden::Proxy, user: user)}
    let(:call_method) { subject.matches?(request) }

    before do
      allow(request.env).to receive(:[]).with('warden').and_return(warden)
      allow(subject).to receive(:feature_enabled?)
    end

    it 'fetches the user from the request' do
      expect(warden).to receive(:user)
      call_method
    end
    it 'calls `with_request` with the current request' do
      expect(subject).to receive(:with_request).with(request)
      call_method
    end
    it 'checks if the feature is enabled for the current user' do
      expect(subject).to receive(:feature_enabled?).with(feature, user)
      call_method
    end
    it 'checks if the feature is enabled within the `with_request` block' do
      allow(subject).to receive(:with_request).with(request)
      expect(subject).to_not receive(:feature_enabled?)
      call_method
    end
  end
  describe '`with_request` protected method' do
    it 'places the request into the thread for the duration of the yield' do
      subject.send(:with_request, request) { expect(Thread.current[described_class::REQUEST_KEY]).to eq(request)}
    end
    it 'restores the thread storage if an error occurs' do
      begin
        subject.send(:with_request, request) { raise 'some error' }
      rescue
      end
      expect(Thread.current[described_class::REQUEST_KEY]).to be_nil
    end
    it 'restores the thread storage if an error does not occur' do
      subject.send(:with_request, request) { }
      expect(Thread.current[described_class::REQUEST_KEY]).to be_nil
    end
  end
end