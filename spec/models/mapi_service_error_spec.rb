require 'rails_helper'

describe MAPIService::Error do
  let(:type) { instance_double(Symbol) }
  let(:code) { instance_double(Symbol) }
  let(:value) { double('Some Value') }

  subject { described_class.new(type, code, value) }

  describe 'initializer' do
    let(:call_method) { described_class.new(type, code, value) }
    it 'assigns the `type` parameter to the `type` attribute' do
      expect(call_method.type).to be(type)
    end
    it 'assigns the `code` parameter to the `code` attribute' do
      expect(call_method.code).to be(code)
    end
    it 'assigns the `value` parameter to the `value` attribute' do
      expect(call_method.value).to be(value)
    end
    it 'sets `value` to nil if none is provided' do
      expect(described_class.new(type, code).value).to be_nil
    end
  end
end