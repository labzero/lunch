require 'rails_helper'

describe Rack::AddResponseHeaders do
  let(:subject) { Rack::AddResponseHeaders }
  let(:key) { ('a'..'z').to_a.shuffle[0,8].join }
  let(:value) { ('a'..'z').to_a.shuffle[0,8].join }
  let(:options_hash) { {"#{key}" => value} }
  let(:status) { double('some status code') }
  let(:headers) { {} }
  let(:body) { double('some response body') }
  let(:response) { [status, headers, body] }
  let(:app) { double('some app') }
  let(:options) { double('an options hash')}
  let(:test_instance) { subject.new(app) }
  let(:options_test_instance) { subject.new(app, options_hash) }
  
  describe 'initialize' do
    it 'sets the instance variable @app to its first arg' do
      expect(test_instance.instance_variable_get(:@app)).to eq(app)
    end
    it 'sets the instance variable @options to an empty hash if nothing is passed' do
      expect(test_instance.instance_variable_get(:@options)).to eq({})
    end
    it 'sets the instance variable @options to the hash it is passed' do
      expect(options_test_instance.instance_variable_get(:@options)).to eq(options_hash)
    end
  end
  
  describe 'call' do
    let (:call_method) { options_test_instance.call('foo') }
    before { allow(app).to receive(:call).and_return(response) }
    it 'returns the result of `call` on the given app' do
      expect(call_method).to eq(response)
    end
    it 'adds the @options set during initialization to the headers hash' do
      expect(call_method[1][key]).to eq(value)
    end
  end
end