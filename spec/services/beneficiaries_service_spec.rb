require 'rails_helper'

describe BeneficiariesService do
  let(:member_id) { SecureRandom.hex }
  let(:response) {[instance_double(Hash, with_indifferent_access: nil)]}
  let(:beneficiary) { double('Beneficiary', :[] => nil) }

  subject { BeneficiariesService.new(ActionDispatch::TestRequest.new) }

  describe 'the `beneficiaries` method' do
    let(:call_method) { subject.beneficiaries(member_id) }
    before {
      allow(subject).to receive(:get_json).and_return(response)
      response.each { |member| allow(member).to receive(:with_indifferent_access).and_return(beneficiary) }
    }
    it 'calls the `get_json` method with the proper method name' do
      expect(subject).to receive(:get_json).with(:beneficiaries, anything)
      call_method
    end
    it 'calls the `get_json` method with the proper endpoint' do
      expect(subject).to receive(:get_json).with(anything, "member/#{member_id}/beneficiaries")
      call_method
    end
    it 'returns the array of member hashes' do
      allow(subject).to receive(:format_beneficiaries).and_return(response)
      expect(call_method).to eq(response)
    end
  end

  describe 'private methods' do
    describe '`format_beneficiaries` method' do
      let(:beneficiaries) { JSON.parse(File.read(File.join(Rails.root, 'spec', 'fixtures', 'beneficiaries.json'))).collect{|x| x.with_indifferent_access} }

      [:name, :address].each do |property|
        it "returns an object with a `#{property}` formatted as a string" do
          expect(subject.send(:format_beneficiaries, beneficiaries).first[property]).to be_kind_of(String)
        end
      end
    end
  end
end