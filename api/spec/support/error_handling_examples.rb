RSpec.shared_examples 'a MAPI endpoint with JSON error handling' do |endpoint, action, module_name, module_method, params={}|
  let(:logger) { double('MAPI logger', error: nil) }
  let(:error_message) { SecureRandom.hex }
  let(:error_code) { SecureRandom.hex }
  let(:error) { MAPI::Shared::Errors::ValidationError.new(error_message, error_code) }
  let(:make_request) { send(action, endpoint, params) }
  let(:response_body) { make_request; JSON.parse(last_response.body).with_indifferent_access }
  let(:response_status) { make_request; last_response.status }

  before do
    allow_any_instance_of(MAPI::ServiceApp).to receive(:logger).and_return(logger)
    allow(module_name).to receive(module_method).and_raise(error)
  end

  describe "when the `#{module_name}.#{module_method}` method returns a ValidationError" do
    it 'returns a 400' do
      expect(response_status).to eq(400)
    end
    it 'logs an error message' do
      expect(logger).to receive(:error).with(error_message)
      make_request
    end
    it 'returns an error code of in its body' do
      expect(response_body[:error][:code]).to eq(error_code)
    end
  end
  describe "when the `#{module_name}.#{module_method}` method returns an error that is not a ValidationError" do
    let(:error) { StandardError.new(error_message) }

    it 'returns a 400' do
      expect(response_status).to eq(400)
    end
    it 'logs the error' do
      expect(logger).to receive(:error).with(error)
      make_request
    end
    it 'returns `unknown` as the error `type`' do
      expect(response_body[:error][:type]).to eq('unknown')
    end
    it 'returns `unknown` as the error `code`' do
      expect(response_body[:error][:code]).to eq('unknown')
    end
    it 'returns the error message as the error `value`' do
      expect(response_body[:error][:value]).to eq(error_message)
    end
  end
end