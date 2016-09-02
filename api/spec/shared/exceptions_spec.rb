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
    it 'has a `type` set to `validation`' do
      expect(subject.new(message).type).to eq(:validation)
    end
  end
end

describe MissingFieldError do
  subject { MissingFieldError }
  let(:message) { SecureRandom.hex }

  it 'has a `type` set to `blank`' do
    expect(subject.new(message).type).to eq(:blank)
  end
end

describe InvalidFieldError do
  subject { InvalidFieldError }
  let(:message) { SecureRandom.hex }

  it 'has a `type` set to `invalid`' do
    expect(subject.new(message).type).to eq(:invalid)
  end
end

describe CustomTypedFieldError do
  subject { CustomTypedFieldError }
  let(:message) { SecureRandom.hex }
  let(:type) { SecureRandom.hex }

  it 'has a `type` set to the provided type' do
    expect(subject.new(message, type).type).to eq(type)
  end
end