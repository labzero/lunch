require 'rails_helper'

RSpec.describe BeneficiaryRequest, :type => :model do
  let(:member_id) { rand(1000..9999) }

  subject { described_class.new(member_id) }

  describe 'initialization' do
    let(:request) { double('request') }
    let(:new_loc) { BeneficiaryRequest.new(member_id) }
    describe 'when a request arg is passed' do
      let(:new_loc) { BeneficiaryRequest.new(member_id, request) }
      it 'sets `request` to the passed arg' do
        expect(new_loc.request).to eq(request)
      end
    end
    describe 'when a request arg is not' do
      before { allow(ActionDispatch::TestRequest).to receive(:new).and_return(request) }
      it 'creates a new instance of ActionDispatch::TestRequest' do
        expect(ActionDispatch::TestRequest).to receive(:new)
        new_loc
      end
      it 'sets `request` to the test arg' do
        expect(new_loc.request).to eq(request)
      end
    end
    it 'sets `member_id` to the passed member_id arg' do
      expect(new_loc.member_id).to eq(member_id)
    end
  end

  describe 'class methods' do
    describe '`from_json`' do
      let(:json) { double('some JSON') }
      let(:request) { double('request') }
      let(:loc) { instance_double(BeneficiaryRequest, from_json: nil) }
      let(:call_method) { BeneficiaryRequest.from_json(json, request) }

      before { allow(BeneficiaryRequest).to receive(:new).and_return(loc) }

      it 'creates a new `BeneficiaryRequest`' do
        expect(BeneficiaryRequest).to receive(:new).and_return(loc)
        call_method
      end
      it 'calls `from_json` with the passed json' do
        expect(loc).to receive(:from_json).with(json)
        call_method
      end
      it 'returns the `BeneficiaryRequest`' do
        allow(loc).to receive(:from_json).and_return(loc)
        expect(call_method).to eq(loc)
      end
    end

    describe '`policy_class`' do
      it 'returns the LettersOfCreditPolicy class' do
        expect(described_class.policy_class).to eq(LettersOfCreditPolicy)
      end
    end
  end

  describe 'instance methods' do
    describe 'the `id` getter' do
      let(:id) { SecureRandom.hex }
      context 'when the attribute already exists' do
        before { subject.instance_variable_set(:@id, id) }
        it 'returns the attribute' do
          expect(subject.id).to eq(id)
        end
      end
      context 'when the attribute does not yet exist' do
        it 'sets the attribute to the result of calling `SecureRandom.uuid`' do
          allow(SecureRandom).to receive(:uuid).and_return(id)
          expect(subject.id).to be(id)
        end
      end
    end

    describe '`attributes`' do
      let(:call_method) { subject.attributes }
      persisted_attributes = described_class::READ_ONLY_ATTRS + described_class::ACCESSIBLE_ATTRS - described_class::SERIALIZATION_EXCLUDE_ATTRS

      before do
        persisted_attributes.each { |attr| allow(subject).to receive(attr) }
      end

      it 'returns a hash of attribute values' do
        expect(call_method).to be_kind_of(Hash)
      end

      (persisted_attributes).each do |attr|
        it "includes the key `#{attr}` with a value of nil if the attribute is present" do
          value = double('A Value')
          allow(subject).to receive(attr).and_return(value)
          expect(call_method).to have_key(attr)
        end
        it "does not include `#{attr}` if the attribute is nil" do
          allow(subject).to receive(attr).and_return(nil)
          expect(call_method).to_not have_key(attr)
        end
      end

      described_class::SERIALIZATION_EXCLUDE_ATTRS.each do |attr|
        it "does not include `#{attr}`" do
          allow(subject).to receive(attr).and_return(double('A Value'))
          expect(call_method).to_not have_key(attr)
        end
      end
    end

    describe '`attributes=`' do
      read_only_attrs = [:id, :request]
      serialization_exclude_attrs = [:request]
      let(:hash) { {} }
      let(:value) { double('some value') }
      let(:call_method) { subject.send(:attributes=, hash) }

      (described_class::ACCESSIBLE_ATTRS + read_only_attrs - serialization_exclude_attrs).each do |key|
        it "assigns the value found under `#{key}` to the attribute `#{key}`" do
          hash[key.to_s] = value
          call_method
          expect(subject.send(key)).to be(value)
        end
      end
      serialization_exclude_attrs.each do |attr|
        it 'raises an error if it encounters an excluded attribute' do
          hash[attr] = double('A Value')
          expect{call_method}.to raise_error(ArgumentError, "illegal attribute: #{attr}")
        end
      end
      it 'assigns the `owners` attribute after calling `to_set` on the value' do
        expected_value = double('Set of Owners')
        value = double('A Value', to_set: expected_value)
        hash[:owners] = value
        call_method
        expect(subject.owners).to eq(expected_value)
      end
      it 'raises an exception if the hash contains keys that are not `BeneficiaryRequest` attributes' do
        hash[:foo] = 'bar'
        expect{call_method}.to raise_error(ArgumentError, "unknown attribute: foo")
      end
    end
  end
end