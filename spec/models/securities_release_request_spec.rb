require 'rails_helper'

RSpec.describe SecuritiesReleaseRequest, :type => :model do
  before { allow_any_instance_of(CalendarService).to receive(:holidays).and_return([]) }
  describe 'validations' do
    (described_class::BROKER_INSTRUCTION_KEYS + [:delivery_type, :securities]).each do |attr|
      it "should validate the presence of `#{attr}`" do
        expect(subject).to validate_presence_of attr
      end
    end
    described_class::DELIVERY_TYPES.keys.each do |delivery_type|
      describe "when `:delivery_type` is `#{delivery_type}`" do
        before do
          subject.delivery_type = delivery_type
        end
        described_class::DELIVERY_INSTRUCTION_KEYS[delivery_type].each do |attr|
          it "should validate the presence of `#{attr}`" do
            expect(subject).to validate_presence_of attr
          end
        end
      end
    end
    describe '`trade_date_must_come_before_settlement_date`' do
      let(:trade_date_errors) { subject.valid?; subject.errors.messages[:trade_date] || [] }
      let(:today) { Time.zone.today }
      it 'is called as a validator' do
        expect(subject).to receive(:trade_date_must_come_before_settlement_date)
        subject.valid?
      end
      it 'does not add an error if there is no `trade_date`' do
        subject.settlement_date = today
        expect(trade_date_errors).not_to include("must come before 'settlement_date'")
      end
      it 'does not add an error if there is no `settlement_date`' do
        subject.trade_date = today
        expect(trade_date_errors).not_to include("must come before 'settlement_date'")
      end
      it 'adds an error if the `trade_date` comes after the `settlement_date`' do
        subject.trade_date = today
        subject.settlement_date = today - 2.days
        expect(trade_date_errors).to include("must come before 'settlement_date'")
      end
      it 'does not add an error if the `trade_date` comes before the `settlement_date`' do
        subject.trade_date = today - 2.days
        subject.settlement_date = today
        expect(trade_date_errors).not_to include("must come before 'settlement_date'")
      end
      it 'does not add an error if the `trade_date` is equal to the `settlement_date`' do
        subject.trade_date = today
        subject.settlement_date = today
        expect(trade_date_errors).not_to include("must come before 'settlement_date'")
      end
    end
    [[:trade_date, :trade_date_within_range], [:settlement_date, :settlement_date_within_range]].each do |attr_array|
      attr = attr_array.first
      method = attr_array.last
      describe "`#{method}`" do
        let(:call_validation) { subject.send(method) }
        let(:attr_errors) { subject.valid?; subject.errors.messages[attr] || [] }

        before { allow(subject).to receive(:date_within_range) }

        it 'is called as a validator' do
          expect(subject).to receive(method)
          subject.valid?
        end
        it "calls `date_within_range` with the `#{attr}` as an arg" do
          date = instance_double(Date)
          subject.send("#{attr}=", date)
          expect(subject).to receive(:date_within_range).with(date)
          call_validation
        end
        it "adds an error for `#{attr}` if `date_within_range` returns false" do
          allow(subject).to receive(:date_within_range).and_return(false)
          expect(attr_errors).to include('must not be a holiday, weekend, or in the past')
        end
        it "does not add an error for `#{attr}` if `date_within_range` returns true" do
          allow(subject).to receive(:date_within_range).and_return(true)
          expect(attr_errors).to_not include('must not be a holiday, weekend, or in the past')
        end
      end
    end
    describe '`date_within_range`' do
      let(:today) { Time.zone.today }
      let(:max_date) { today + described_class::MAX_DATE_RESTRICTION }
      let(:date) { instance_double(Date, sunday?: false, saturday?: false, :>= => true, :<= => true) }
      let(:call_method) { subject.send(:date_within_range, date) }

      it 'fetches `holidays` from the CalendarService instance with today and the max_date as args' do
        expect_any_instance_of(CalendarService).to receive(:holidays).with(today, max_date).and_return([])
        call_method
      end
      it 'returns nil if passed nil' do
        expect(subject.send(:date_within_range, nil)).to be_nil
      end
      it 'returns false if the provided date is a Saturday' do
        allow(date).to receive(:saturday?).and_return(true)
        expect(call_method).to be false
      end
      it 'returns false if the provided date is a Sunday' do
        allow(date).to receive(:sunday?).and_return(true)
        expect(call_method).to be false
      end
      it 'returns false if the provided date is a bank holiday' do
        allow_any_instance_of(CalendarService).to receive(:holidays).and_return([date])
        expect(call_method).to be false
      end
      it 'returns false if the provided date occurs before today' do
        allow(date).to receive(:>=).with(today).and_return(false)
        expect(call_method).to be false
      end
      it 'returns false if the provided date occurs after today plus the `MAX_DATE_RESTRICTION`' do
        allow(date).to receive(:<=).with(max_date).and_return(false)
        expect(call_method).to be false
      end
      it 'returns true if all of the above conditions are satisfied' do
        expect(call_method).to be true
      end
    end
    describe '`securities_must_have_payment_amount`' do
      let(:call_validation) { subject.send(:securities_must_have_payment_amount) }

      it 'is not called as a validator if the `settlement_type` is `:free`' do
        subject.settlement_type = :free
        expect(subject).not_to receive(:securities_must_have_payment_amount)
        subject.valid?
      end
      describe 'when the `settlement_type` is `:vs_payment`' do
        let(:security_without_payment_amount) { FactoryGirl.build(:security, payment_amount: nil) }
        let(:security_with_payment_amount) { FactoryGirl.build(:security, payment_amount: rand(1000.99999)) }
        before do
          subject.settlement_type = :vs_payment
        end
        it 'is called as a validator' do
          expect(subject).to receive(:securities_must_have_payment_amount)
          subject.valid?
        end
        it 'returns false if there are no securities' do
          expect(call_validation).to be(false)
        end
        it 'returns false if `securities` is an empty array' do
          subject.securities = []
          expect(call_validation).to be(false)
        end
        it 'returns true if all `securities` have a `payment_amount` value' do
          subject.securities = [security_with_payment_amount, security_with_payment_amount]
          expect(call_validation).to be(true)
        end
        it 'returns false if any of the `securities` do not have a `payment_amount` value' do
          subject.securities = [security_with_payment_amount, security_without_payment_amount]
          expect(call_validation).to be(false)
        end
      end
    end
  end

  describe 'class methods' do
    describe '`from_hash`' do
      it 'creates a SecuritiesReleaseRequest from a hash' do
        aba_number = SecureRandom.hex
        securities_request_release = described_class.from_hash({aba_number: aba_number})
        expect(securities_request_release.aba_number).to eq(aba_number)
      end
      describe 'with methods stubbed' do
        let(:hash) { instance_double(Hash) }
        let(:securities_request_release) { instance_double(SecuritiesReleaseRequest, :attributes= => nil) }
        let(:call_method) { described_class.from_hash(hash) }
        before do
          allow(SecuritiesReleaseRequest).to receive(:new).and_return(securities_request_release)
        end
        it 'initializes a new instance of SecuritiesReleaseRequest' do
          expect(SecuritiesReleaseRequest).to receive(:new).and_return(securities_request_release)
          call_method
        end
        it 'calls `attributes=` on the SecuritiesReleaseRequest instance' do
          expect(securities_request_release).to receive(:attributes=).with(hash)
          call_method
        end
        it 'returns the SecuritiesReleaseRequest instance' do
          expect(call_method).to eq(securities_request_release)
        end
      end
    end
  end

  describe 'instance methods' do
    describe '`attributes=`' do
      sym_attrs = [:delivery_type, :transaction_code, :settlement_type]
      date_attrs = [:trade_date, :settlement_date]
      let(:hash) { {} }
      let(:value) { double('some value') }
      let(:call_method) { subject.send(:attributes=, hash) }
      let(:excluded_attrs) { [] }

      (described_class::ACCESSIBLE_ATTRS - date_attrs - sym_attrs).each do |key|
        it "assigns the value found under `#{key}` to the attribute `#{key}`" do
          hash[key.to_s] = value
          call_method
          expect(subject.send(key)).to be(value)
        end
      end
      sym_attrs.each do |key|
        it "assigns a symbolized value found under `#{key}` to the attribute `#{key}`" do
          hash[key.to_s] = double('some value', to_sym: value)
          call_method
          expect(subject.send(key)).to be(value)
        end
      end
      date_attrs.each do |key|
        it "assigns a datefied value found under `#{key}` to the attribute `#{key}`" do
          datefied_value = double('some value as a date')
          allow(Time.zone).to receive(:parse).with(value).and_return(datefied_value)
          hash[key.to_s] = value
          call_method
          expect(subject.send(key)).to be(datefied_value)
        end
      end
      it 'calls `securities=` with the value when the key is `securities`' do
        expect(subject).to receive(:securities=).with(value)
        hash[:securities] = value
        call_method
      end
      it 'raises an exception if the hash contains keys that are not SecuritiesReleaseRequest attributes' do
        hash[:foo] = 'bar'
        expect{call_method}.to raise_error(ArgumentError, "unknown attribute: 'foo'")
      end
    end

    describe '`securities=`' do
      let(:security) { FactoryGirl.build(:security) }
      let(:securities) { [security] }
      let(:call_method) { subject.securities = securities }
      it 'sets `@securities` to an empty array if passed nil' do
        subject.securities = nil
        expect(subject.securities).to eq([])
      end
      it 'tries to parse as JSON if passed a string' do
        expect(JSON).to receive(:parse).with(securities.to_json).and_call_original
        subject.securities = securities.to_json
      end
      describe 'when passed an array of Securities objects' do
        let(:securities) { [security] }
        it 'sets `@securities` to the array of Securities objects' do
          call_method
          expect(subject.securities).to eq(securities)
        end
      end
      describe 'when passed an array of Strings' do
        let(:string_security) { SecureRandom.hex }
        let(:securities) { [string_security, string_security] }

        before do
          allow(Security).to receive(:from_json).and_return(security)
        end
        it 'calls `Security.from_json` on each string' do
          expect(Security).to receive(:from_json).twice.with(string_security)
          call_method
        end
        it 'sets `@securities` to the array of created Securities objects' do
          call_method
          expect(subject.securities).to eq([security, security])
        end
      end
      describe 'when passed an array of Hashes' do
        let(:hashed_security) { {cusip: SecureRandom.hex} }
        let(:securities) { [hashed_security, hashed_security] }

        before do
          allow(Security).to receive(:from_hash).and_return(security)
        end
        it 'calls `Security.from_hash` on each hash' do
          expect(Security).to receive(:from_hash).twice.with(hashed_security)
          call_method
        end
        it 'sets `@securities` to the array of created Securities objects' do
          call_method
          expect(subject.securities).to eq([security, security])
        end
      end
      describe 'when passed an array of anything besides Securities, Strings, or Hashes' do
        let(:call_method) {subject.securities = [43, :foo]  }
        it 'raises an error' do
          expect{call_method}.to raise_error(ArgumentError)
        end
        it 'does not set `@securities`' do
          begin
            call_method
          rescue
          end
          expect(subject.securities).to be_nil
        end
      end
    end

    describe '`broker_instructions`' do
      let(:call_method) { subject.broker_instructions }
      described_class::BROKER_INSTRUCTION_KEYS.each do |key|
        it "returns a hash containing the `#{key}`" do
          value = double('some value')
          subject.send( "#{key.to_s}=", value)
          expect(call_method[key]).to eq(value)
        end
      end
    end

    describe '`delivery_instructions`' do
      let(:call_method) { subject.delivery_instructions }

      described_class::DELIVERY_INSTRUCTION_KEYS.keys.each do |key|
        it "returns a hash containing the `delivery_type` attribute" do
          subject.delivery_type = key
          expect(call_method[:delivery_type]).to eq(key)
        end
        described_class::DELIVERY_INSTRUCTION_KEYS[key].each do |attr|
          if described_class::ACCOUNT_NUMBER_TYPE_MAPPING.values.include?(attr)
            it "returns a hash containing an `account_number` key with the value for `attr`" do
              subject.delivery_type = key
              value = double('some value')
              subject.send( "#{attr.to_s}=", value)
              expect(call_method[:account_number]).to eq(value)
            end
          else
            it "returns a hash containing the `#{attr}`" do
              subject.delivery_type = key
              value = double('some value')
              if attr == :clearing_agent_fed_wire_address
                subject.clearing_agent_fed_wire_address_1 = value
              else
                subject.send( "#{attr.to_s}=", value)
              end
              expect(call_method[attr]).to eq(value)
            end
          end
        end
      end
    end
  end
end