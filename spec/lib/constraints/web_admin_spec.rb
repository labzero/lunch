require 'rails_helper'


RSpec.describe Constraints::WebAdmin do
  describe '`initialize` method' do
    let(:query) { instance_double(Symbol, 'Query Method') }
    let(:call_method) { described_class.new(query) }
    before do
      allow(query).to receive(:to_sym).and_return(query)
    end
    it 'symbolizes the provided query method' do
      expect(query).to receive(:to_sym)
      call_method
    end
    it 'sets the `query` to the provided query method' do
      expect(call_method.query).to be(query)
    end
    it 'sets the `query` to `show?` if none is provided' do
      expect(subject.query).to be(:show?)
    end
  end

  describe '`matches?` method' do
    let(:request) { ActionDispatch::TestRequest.new }
    let(:user) { instance_double(User) }
    let(:warden) { instance_double(Warden::Proxy, user: user)}
    let(:policy) { instance_double(WebAdminPolicy, subject.query => false) }
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

    it 'returns the result of calling the `query` method on the policy' do
      result = double('A Result')
      allow(policy).to receive(subject.query).and_return(result)
      expect(call_method).to be(result)
    end
  end

  describe '`query` attribute' do
    it 'returns the value in `@query`' do
      a_value = double('A Value')
      subject.instance_variable_set(:@query, a_value)
      expect(subject.query).to be(a_value)
    end
  end
end