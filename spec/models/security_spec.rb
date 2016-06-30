require 'rails_helper'

RSpec.describe Security, :type => :model do
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

  describe '`attributes=`' do
    let(:hash) { {} }
    let(:value) { double('some value') }
    let(:call_method) { subject.send(:attributes=, hash) }

    (described_class::ACCESSIBLE_ATTRS - [:cusip]).each do |key|
      it "assigns the value found under `#{key}` to the attribute `#{key}`" do
        hash[key.to_s] = value
        call_method
        expect(subject.send(key)).to be(value)
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