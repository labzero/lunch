require 'rails_helper'


RSpec.describe Constraints::WebAdmin do
  describe '`matches?` method' do
    let(:request) { ActionDispatch::TestRequest.new }
    let(:user) { double(User) }
    let(:warden) { double(Warden::Proxy, user: user)}
    let(:policy) { double(WebAdminPolicy, show?: false) }
    let(:call_method) { subject.matches?(request) }

    before do
      allow(request.env).to receive(:[]).with('warden').and_return(warden)
      allow(WebAdminPolicy).to receive(:new).and_return(policy)
    end

    it 'fetches the user from the request' do
      expect(warden).to receive(:user)
      call_method
    end
    it 'constructs a new WebAdminPolicy object' do
      expect(WebAdminPolicy).to receive(:new).with(user, request).and_return(policy)
      call_method
    end
    it 'returns the result of calling `WebAdminPolicy.show?`' do
      result = double('A Result')
      allow(policy).to receive(:show?).and_return(result)
      expect(call_method).to be(result)
    end
  end
end