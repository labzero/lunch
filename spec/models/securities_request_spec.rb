require 'rails_helper'

RSpec.describe SecuritiesRequest, :type => :model do
  before { allow_any_instance_of(CalendarService).to receive(:holidays).and_return([]) }
  describe 'validations' do
    (described_class::BROKER_INSTRUCTION_KEYS + [:delivery_type, :securities, :kind, :form_type]).each do |attr|
      it "should validate the presence of `#{attr}`" do
        allow(subject).to receive("#{attr}=")
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
      let(:call_validation) { subject.send(:trade_date_must_come_before_settlement_date) }
      let(:today) { Time.zone.today }
      it 'is called as a validator' do
        expect(subject).to receive(:trade_date_must_come_before_settlement_date)
        subject.valid?
      end
      it 'does not add an error if there is no `trade_date`' do
        subject.settlement_date = today
        expect(subject.errors).not_to receive(:add)
        call_validation
      end
      it 'does not add an error if there is no `settlement_date`' do
        subject.trade_date = today
        expect(subject.errors).not_to receive(:add)
        call_validation
      end
      it 'adds an error if the `trade_date` comes after the `settlement_date`' do
        subject.trade_date = today
        subject.settlement_date = today - 2.days
        expect(subject.errors).to receive(:add).with(:settlement_date, :before_trade_date)
        call_validation
      end
      it 'does not add an error if the `trade_date` comes before the `settlement_date`' do
        subject.trade_date = today - 2.days
        subject.settlement_date = today
        expect(subject.errors).not_to receive(:add)
        call_validation
      end
      it 'does not add an error if the `trade_date` is equal to the `settlement_date`' do
        subject.trade_date = today
        subject.settlement_date = today
        expect(subject.errors).not_to receive(:add)
        call_validation
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
        it "does not add an error if there is no value for `#{attr}`" do
          expect(subject.errors).not_to receive(:add)
          call_validation
        end
        describe "when there is a value for `#{attr}`" do
          before { subject.send("#{attr}=", instance_double(Date)) }

          it "adds an error for `#{attr}` if `date_within_range` returns false" do
            allow(subject).to receive(:date_within_range).and_return(false)
            expect(subject.errors).to receive(:add).with(attr, :invalid)
            call_validation
          end
          it "does not add an error for `#{attr}` if `date_within_range` returns true" do
            allow(subject).to receive(:date_within_range).and_return(true)
            expect(subject.errors).not_to receive(:add)
            call_validation
          end
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
        it 'does not add an error if there are no securities' do
          expect(subject.errors).not_to receive(:add)
          call_validation
        end
        it 'does not add an error if `securities` is an empty array' do
          subject.securities = []
          expect(subject.errors).not_to receive(:add)
          call_validation
        end
        it 'does not add an error if all `securities` have a `payment_amount` value' do
          subject.securities = [security_with_payment_amount, security_with_payment_amount]
          expect(subject.errors).not_to receive(:add)
          call_validation
        end
        it 'adds an error if any of the `securities` do not have a `payment_amount` value' do
          subject.securities = [security_with_payment_amount, security_without_payment_amount]
          expect(subject.errors).to receive(:add).with(:securities, :payment_amount)
          call_validation
        end
      end
    end
  end

  describe 'class methods' do
    describe '`from_hash`' do
      it 'creates a `SecuritiesRequest` from a hash' do
        aba_number = SecureRandom.hex
        securities_request_release = described_class.from_hash({aba_number: aba_number})
        expect(securities_request_release.aba_number).to eq(aba_number)
      end
      describe 'with methods stubbed' do
        let(:hash) { instance_double(Hash) }
        let(:securities_request_release) { instance_double(SecuritiesRequest, :attributes= => nil) }
        let(:call_method) { described_class.from_hash(hash) }
        before do
          allow(SecuritiesRequest).to receive(:new).and_return(securities_request_release)
        end
        it 'initializes a new instance of `SecuritiesRequest`' do
          expect(SecuritiesRequest).to receive(:new).and_return(securities_request_release)
          call_method
        end
        it 'calls `attributes=` on the `SecuritiesRequest` instance' do
          expect(securities_request_release).to receive(:attributes=).with(hash)
          call_method
        end
        it 'returns the `SecuritiesRequest` instance' do
          expect(call_method).to eq(securities_request_release)
        end
      end
    end
  end

  describe 'instance methods' do
    describe '`kind=`' do
      let(:kind) { described_class::KINDS.sample }
      let(:call_method) { subject.kind = kind }

      it 'raises an error if the kind is invalid' do
        expect{subject.kind = SecureRandom.hex}.to raise_error(ArgumentError, "`kind` must be one of: #{described_class::KINDS}")
      end
      it 'assigns `@kind` to the passed value' do
        call_method
        expect(subject.kind).to eq(kind)
      end
      describe 'when `kind` is `:pledge_transfer`' do
        before { subject.kind = :pledge_transfer }
        it 'sets `@form_type` to `:pledge_intake`' do
          expect(subject.form_type).to eq(:pledge_intake)
        end
        it 'sets `@delivery_type` to `:transfer`' do
          expect(subject.delivery_type).to eq(:transfer)
        end
      end
      describe 'when `kind` is `:safekept_transfer`' do
        before { subject.kind = :safekept_transfer }
        it 'sets `@form_type` to `:pledge_release`' do
          expect(subject.form_type).to eq(:pledge_release)
        end
        it 'sets `@delivery_type` to `:transfer`' do
          expect(subject.delivery_type).to eq(:transfer)
        end
      end
      (described_class::KINDS - [:pledge_transfer, :safekept_transfer]).each do |kind|
        describe "when `kind` is `#{kind}`" do
          before { subject.kind = kind }
          it "sets `@form_type` to `#{kind}`" do
            expect(subject.form_type).to eq(kind)
          end
        end
      end
    end
    describe '`form_type=`' do
      let(:form_type) { described_class::FORM_TYPES.sample }
      let(:call_method) { subject.form_type = form_type }

      it 'raises an error if the form_type is invalid' do
        expect{subject.form_type = SecureRandom.hex}.to raise_error(ArgumentError, "`form_type` must be one of: #{described_class::FORM_TYPES}")
      end
      it 'assigns `@form_type` to the passed value' do
        call_method
        expect(subject.form_type).to eq(form_type)
      end
      describe 'assigning `@kind`' do
        describe 'when `delivery_type` equals `:transfer`' do
          before { subject.delivery_type = :transfer }

          describe 'when `form_type` is `:pledge_intake`' do
            it 'sets `@kind` to `:pledge_transfer`' do
              subject.form_type = :pledge_intake
              expect(subject.kind).to eq(:pledge_transfer)
            end
          end
          describe 'when `form_type` is `:pledge_release`' do
            it 'sets `@kind` to `:safekept_transfer`' do
              subject.form_type = :pledge_release
              expect(subject.kind).to eq(:safekept_transfer)
            end
          end
          (described_class::FORM_TYPES - [:pledge_intake, :pledge_release]).each do |form_type|
            describe "when `form_type` is `#{form_type}`" do
              it 'raises an error' do
                expect{subject.form_type = form_type}.to raise_error(ArgumentError, '`form_type` must be :pledge_intake or :pledge_release when `delivery_type` is :transfer')
              end
            end
          end
        end
        describe 'when `delivery_type` does not equal `:transfer`' do
          it 'sets `@kind` to `form_type`' do
            call_method
            expect(subject.kind).to eq(form_type)
          end
        end
      end
    end
    describe '`delivery_type=`' do
      let(:delivery_type) { described_class::DELIVERY_TYPES.keys.sample }
      let(:call_method) { subject.delivery_type = delivery_type }

      it 'raises an error if the form_type is invalid' do
        expect{subject.delivery_type = SecureRandom.hex}.to raise_error(ArgumentError, "`delivery_type` must be one of: #{described_class::DELIVERY_TYPES.keys}")
      end
      it 'assigns `@delivery_type` to the passed value' do
        call_method
        expect(subject.delivery_type).to eq(delivery_type)
      end
      describe 'when `delivery_type` equals `:transfer`' do
        let(:call_method) { subject.delivery_type = :transfer }
        it 'does not assign @kind if there is no @form_type' do
          call_method
          expect(subject.kind).to be_nil
        end
        describe 'when there is a @form_type' do
          (described_class::FORM_TYPES - [:pledge_intake, :pledge_release]).each do |form_type|
            it "raises an error if the @form_type is `#{form_type}`" do
              subject.form_type = form_type
              expect{call_method}.to raise_error(ArgumentError, '`form_type` must be :pledge_intake or :pledge_release when `delivery_type` is :transfer')
            end
          end
          it 'sets @kind to `:pledge_transfer` when @form_type equals `:pledge_intake`' do
            subject.form_type = :pledge_intake
            call_method
            expect(subject.kind).to eq(:pledge_transfer)
          end
          it 'sets @kind to `:safekept_transfer` when @form_type equals `:pledge_release`' do
            subject.form_type = :pledge_release
            call_method
            expect(subject.kind).to eq(:safekept_transfer)
          end
        end
      end
    end
    describe '`attributes=`' do
      sym_attrs = [:transaction_code, :settlement_type]
      date_attrs = [:trade_date, :settlement_date]
      custom_attrs = [:request_id, :form_type, :kind, :delivery_type]
      let(:hash) { {} }
      let(:value) { double('some value') }
      let(:call_method) { subject.send(:attributes=, hash) }
      let(:excluded_attrs) { [] }

      (described_class::ACCESSIBLE_ATTRS - date_attrs - sym_attrs - custom_attrs).each do |key|
        it "assigns the value found under `#{key}` to the attribute `#{key}`" do
          hash[key.to_s] = value
          call_method
          expect(subject.send(key)).to be(value)
        end
      end
      custom_attrs.each do |key|
        it "assigns the value found under `#{key}` to the attribute `#{key}`" do
          expect(subject).to receive(:"#{key}=").with(value)
          hash[key] = value
          call_method
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
      it 'raises an exception if the hash contains keys that are not `SecuritiesRequest` attributes' do
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

    describe '`request_id=`' do
      it 'sets the `request_id` to the supplied value' do
        request_id = SecureRandom.hex
        subject.request_id = request_id
        expect(subject.request_id).to eq(request_id)
      end
      it 'sets the `request_id` to nil if passed an empty string' do
        subject.request_id = ""
        expect(subject.request_id).to be_nil
      end
      it 'sets the `request_id` to nil if passed nil' do
        subject.request_id = nil
        expect(subject.request_id).to be_nil
      end
      it 'sets the `request_id` to nil if passed false' do
        subject.request_id = false
        expect(subject.request_id).to be_nil
      end
      it 'raises an exception if passed `true`' do
        expect{subject.request_id = true}.to raise_error(ArgumentError)
      end
      it 'raises an exception if passed an object' do
        expect{subject.request_id = Object.new}.to raise_error(ArgumentError)
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