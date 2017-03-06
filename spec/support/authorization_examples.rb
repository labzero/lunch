RSpec.shared_examples 'an authorization required method' do |method, action, policy, queries, params=nil|
  Array.wrap(queries).each do |query|
    it 'authorizes the request' do
      allow(subject).to receive(:authorize).with(policy, anything)
      expect(subject).to receive(:authorize).with(policy, query)
      begin
        self.send(method, action, params)
      rescue Exception => e
        Rails.logger.warn("Ignoring exception: #{e}") # we don't care if the request fails, so long as it passes its expect
      end
      
    end
    it 'rejects the request if user is not authorized' do
      allow(subject).to receive(:authorize).with(policy, query).and_raise Pundit::NotAuthorizedError
      expect{self.send(method, action, params)}.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end

RSpec.shared_examples 'a resource-based authorization required method' do |method, action, resource, query, params=nil|
  it 'authorizes the request' do
    expect(subject).to receive(:authorize).with(send(resource.to_sym), query)
    begin
      self.send(method, action, params)
    rescue Exception => e
      Rails.logger.warn("Ignoring exception: #{e}") # we don't care if the request fails, so long as it passes its expect
    end
    
  end
  it 'rejects the request if user is not authorized' do
    allow(subject).to receive(:authorize).with(send(resource.to_sym), query).and_raise Pundit::NotAuthorizedError
    expect{self.send(method, action, params)}.to raise_error(Pundit::NotAuthorizedError)
  end
end