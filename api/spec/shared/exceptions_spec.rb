require 'spec_helper'
include MAPI::Shared::Errors

describe ValidationError do
  subject { ValidationError }
  describe 'initialize' do
    let(:message) { SecureRandom.hex }
    let(:code) { SecureRandom.hex }
    let(:call_method) { subject.new(message, code) }
    it 'sets @code to code' do
      expect(call_method.code).to be(code)
    end
  end
end
