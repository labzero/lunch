require 'rails_helper'

RSpec.describe Security, :type => :model do
  describe 'validations' do
    required_attrs = described_class::REQUIRED_ATTRS
    it "validates the presence of `:cusip`" do
      expect(subject).to validate_presence_of :cusip
    end
    described_class::CURRENCY_ATTRIBUTES.each do |attr|
      it "validates the numericality of `#{attr}`" do
        expect(subject).to validate_numericality_of attr
      end
      unless required_attrs.include?(attr)
        it "does not add a validation error if `#{attr}` is blank" do
          subject.valid?
          expect(subject.errors.keys).not_to include(attr)
        end
      end
    end
    it 'checks to see if `:original_par` is greater than 0' do
      expect(subject).to validate_numericality_of(:original_par).is_greater_than(0)
    end
    describe '`cusip_format`' do
      let(:cusip) { SecureRandom.hex }
      let(:cusip_validator) { instance_double(SecurityIdentifiers::CUSIP, :valid? => true ) }
      let(:call_validation) { subject.send(:cusip_format) }

      before { allow(SecurityIdentifiers::CUSIP).to receive(:new).and_return(cusip_validator) }

      it 'is called as a validator' do
        expect(subject).to receive(:cusip_format)
        subject.valid?
      end
      it 'does not add an error if there is no `cusip`' do
        expect(subject.errors).not_to receive(:add)
        call_validation
      end
      describe 'when there is a value for `cusip`' do
        let(:cusip) { SecureRandom.hex.upcase }
        before { subject.cusip = cusip }

        it 'creates a new instance of `SecurityIdentifiers::CUSIP` with the provided cusip' do
          expect(SecurityIdentifiers::CUSIP).to receive(:new).with(cusip).and_return(cusip_validator)
          call_validation
        end
        it 'adds an errorif `SecurityIdentifiers::CUSIP#valid?` returns false' do
          allow(cusip_validator).to receive(:valid?).and_return(false)
          expect(subject.errors).to receive(:add).with(:cusip, :invalid)
          call_validation
        end
        it 'does not add an error if `SecurityIdentifiers::CUSIP#valid?` returns true' do
          allow(cusip_validator).to receive(:valid?).and_return(true)
          expect(subject.errors).not_to receive(:add)
          call_validation
        end
        it 'adds an error if `SecurityIdentifiers::CUSIP#valid?` raises a `SecurityIdentifiers::InvalidFormat` error' do
          allow(cusip_validator).to receive(:valid?).and_raise(SecurityIdentifiers::InvalidFormat)
          expect(subject.errors).to receive(:add).with(:cusip, :invalid)
          call_validation
        end
      end
    end
  end
  describe 'class methods' do
    describe '`from_json`' do
      it 'creates a Security from a JSONed hash' do
        description = SecureRandom.hex
        security = described_class.from_json({description: description}.to_json)
        expect(security.description).to eq(description)
      end
      describe 'with methods stubbed' do
        let(:json) { instance_double(String) }
        let(:parsed_json) { instance_double(Hash) }
        let(:call_method) { described_class.from_json(json) }
        before do
          allow(JSON).to receive(:parse).and_return(parsed_json)
          allow(parsed_json).to receive(:with_indifferent_access).and_return(parsed_json)
          allow(described_class).to receive(:from_hash)
        end

        it 'parses the json it is passed' do
          expect(JSON).to receive(:parse).with(json).and_return(parsed_json)
          call_method
        end
        it 'calls `with_indifferent_access` on the parsed hash' do
          expect(parsed_json).to receive(:with_indifferent_access).and_return(parsed_json)
          call_method
        end
        it 'feeds the hash into the `from_hash` class method' do
          expect(described_class).to receive(:from_hash).with(parsed_json)
          call_method
        end
      end
    end

    describe '`from_hash`' do
      it 'creates a Security from a hash' do
        description = SecureRandom.hex
        security = described_class.from_hash({description: description})
        expect(security.description).to eq(description)
      end
      describe 'with methods stubbed' do
        let(:hash) { instance_double(Hash) }
        let(:security) { instance_double(Security, :attributes= => nil) }
        let(:call_method) { described_class.from_hash(hash) }
        before do
          allow(Security).to receive(:new).and_return(security)
        end
        it 'initializes a new instance of Security' do
          expect(Security).to receive(:new).and_return(security)
          call_method
        end
        it 'calls `attributes=` on the Security instance' do
          expect(security).to receive(:attributes=).with(hash)
          call_method
        end
        it 'returns the Security instance' do
          expect(call_method).to eq(security)
        end
      end
    end
    describe '`human_custody_account_type_to_status`' do
      ['P', 'p', :P, :p].each do |custody_account_type|
        it "returns '#{I18n.t('securities.manage.pledged')}' if it is passed '#{custody_account_type}'" do
          expect(described_class.human_custody_account_type_to_status(custody_account_type)).to eq(I18n.t('securities.manage.pledged'))
        end
      end
      ['U', 'u', :U, :u].each do |custody_account_type|
        it "returns '#{I18n.t('securities.manage.safekept')}' if it is passed '#{custody_account_type}'" do
          expect(described_class.human_custody_account_type_to_status(custody_account_type)).to eq(I18n.t('securities.manage.safekept'))
        end
      end
      it "returns '#{I18n.t('global.missing_value')}' if passed anything other than 'P', :P, 'p', :p, 'U', :U, 'u' or :u" do
        ['foo', 2323, :bar, nil].each do |custody_account_type|
          expect(described_class.human_custody_account_type_to_status(custody_account_type)).to eq(I18n.t('global.missing_value'))
        end
      end
    end
  end

  describe '`attributes`' do
    let(:call_method) { subject.attributes }
    let(:sample_attrs) { (described_class::ACCESSIBLE_ATTRS - [:cusip]).sample(5) }

    before do
      sample_attrs.each do |attr|
        subject.send("#{attr}=", double('value'))
      end
    end

    it 'returns a hash with keys equal to the ACCESSIBLE_ATTRS it has values for' do
      expect(call_method.keys.sort).to eq(sample_attrs.sort)
    end
    it 'returns a hash whose values are all nil' do
      expect(call_method.values.length).to be > 0
      call_method.values.each { |value| expect(value).to be nil }
    end
    it 'does not return attributes that are not cleared as ACCESSIBLE_ATTRS' do
      subject.errors.add(:base, :foo)
      expect(call_method.keys).not_to include(:errors)
    end
  end

  describe '`attributes=`' do
    let(:hash) { {} }
    let(:value) { double('some value', is_a?: nil, nil?: nil) }
    let(:call_method) { subject.send(:attributes=, hash) }

    (described_class::ACCESSIBLE_ATTRS - described_class::CURRENCY_ATTRIBUTES - [:cusip]).each do |key|
      it "assigns the value found under `#{key}` to the attribute `#{key}`" do
        hash[key.to_s] = value
        call_method
        expect(subject.send(key)).to be(value)
      end
    end
    described_class::CURRENCY_ATTRIBUTES.each do |key|
      it 'calls `to_f` on the value when the value is a Numeric' do
        hash[key.to_s] = value
        allow(value).to receive(:is_a?).with(Numeric).and_return(true)
        expect(value).to receive(:to_f)
        call_method
      end
      it 'calls `to_f` on the value when the value is nil' do
        hash[key.to_s] = value
        allow(value).to receive(:nil?).and_return(true)
        expect(value).to receive(:to_f)
        call_method
      end
      it 'does not call `to_f` if the value is a non-nil, non-Numeric' do
        hash[key.to_s] = value
        expect(value).not_to receive(:to_f)
        call_method
      end
    end
    it 'calls the `cusip=` setter with the value found under `cusip`' do
      hash['cusip'] = value
      expect(subject).to receive(:cusip=).with(value)
      call_method
    end
    it 'raises an exception if the hash contains keys that are not Security attributes' do
      hash[:foo] = 'bar'
      expect{call_method}.to raise_error(ArgumentError, "unknown attribute: 'foo'")
    end
  end

  describe '`cusip=`' do
    it "assigns the upcased value it is passed to the attribute `:cusip`" do
      value = SecureRandom.hex
      subject.cusip = value
      expect(subject.cusip).to eq(value.upcase)
    end
    it "assigns nil for the attribute `:cusip` if the passed value for `:cusip` is nil" do
      subject.cusip = nil
      expect(subject.cusip).to be(nil)
    end
  end
end