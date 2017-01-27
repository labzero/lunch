require 'rails_helper'

describe BeneficiariesService do
  let(:beneficiaries) {[
    {'name' => SecureRandom.hex, 'address' => SecureRandom.hex},
    {'name' => SecureRandom.hex, 'address' => SecureRandom.hex},
    {'name' => SecureRandom.hex, 'address' => SecureRandom.hex}
  ]}
  before { stub_const("#{described_class}::BENEFICIARIES", beneficiaries) }

  describe 'the `all` method' do
    let(:call_method) { subject.all }
    it 'returns an array of all beneficiaries' do
      expect(call_method).to eq(beneficiaries)
    end
    it 'returns information about each beneficiary as an indifferent hash' do
      results = call_method
      expect(beneficiaries.length).to be > 0
      beneficiaries.each_with_index do |beneficiary, i|
        expect(results[i][:name]).to eq(beneficiary['name'])
      end
    end
  end
end