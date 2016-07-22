RSpec.shared_examples 'a MAPI backed service object method' do |method, params=nil, action=:get, return_value=nil, parses_json=true, &context_block|
  if context_block.present?
    context_block.call
  else
    let(:call_method) { subject.send(method.to_sym, *params) }
  end
  it 'should return nil if there was an API error' do
    allow_any_instance_of(RestClient::Resource).to receive(action).and_raise(RestClient::InternalServerError)
    expect(call_method).to eq(return_value)
  end
  it 'should return nil if there was a connection error' do
    allow_any_instance_of(RestClient::Resource).to receive(action).and_raise(Errno::ECONNREFUSED)
    expect(call_method).to eq(return_value)
  end
  if parses_json
    it 'returns nil if there is a JSON parsing error' do
      allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      allow(Rails.logger).to receive(:warn)
      expect(call_method).to be(return_value)
    end
  end
end