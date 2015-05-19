RSpec.shared_examples 'an authorization required method' do |method, action, policy, query, params=nil|
  it 'should authorize the request' do
    expect(subject).to receive(:authorize).with(policy, query)
    self.send(method, action, params)
  end
  it 'should reject the request if user is not authorized' do
    allow(subject).to receive(:authorize).with(policy, query).and_raise Pundit::NotAuthorizedError
    expect{self.send(method, action, params)}.to raise_error(Pundit::NotAuthorizedError)
  end
end