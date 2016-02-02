require 'rails_helper'

RSpec.describe Member, type: :model do
  let(:id) { SecureRandom.hex }
  subject { described_class.new(id) }
  describe '`initializer` method' do
    it 'stores the supplied ID' do
      member = described_class.new(id)
      expect(member.instance_variable_get(:@id)).to eq(id)
    end
    it 'raises an error if a nil ID is provided' do
      expect{described_class.new(nil)}.to raise_error
    end
    it 'raises an error if a false ID is provided' do
      expect{described_class.new(false)}.to raise_error
    end
  end
  describe '`flipper_id` method' do
    it 'returns a string representing the members ID' do
      expect(subject.flipper_id).to eq("FHLB-#{id}")
    end
  end
  describe '`id` method' do
    it 'returns the stored ID' do
      expect(subject.id).to eq(id)
    end
  end
end