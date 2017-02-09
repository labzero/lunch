require 'rails_helper'

RSpec.describe LetterOfCredit, :type => :model do
  let(:today) { Time.zone.today }
  let(:calendar_service) { instance_double(CalendarService, holidays: [], find_next_business_day: today) }

  before { allow(CalendarService).to receive(:new).and_return(calendar_service) }

  describe 'validations' do
    [:beneficiary_name, :amount, :issue_date, :expiration_date].each do |attr|
      it "validates the presence of `#{attr}`" do
        expect(subject).to validate_presence_of attr
      end
    end
    it 'validates that `amount` is an integer greater than zero' do
      is_expected.to validate_numericality_of(:amount).only_integer
    end
    it 'validates tha `amount` is greater than zero' do
      is_expected.to validate_numericality_of(:amount).is_greater_than(0)
    end
    [:issue_date_must_come_before_expiration_date, :issue_date_within_range, :expiration_date_within_range].each do |method|
      it "calls `#{method}` as a validator" do
        expect(subject).to receive(method)
        subject.valid?
      end
    end
    describe '`issue_date_must_come_before_expiration_date`' do
      let(:call_validator) { subject.send(:issue_date_must_come_before_expiration_date) }
      [:issue_date, :expiration_date].each do |attr|
        it "does not add an error if there is no `#{attr}`" do
          subject.send(:"#{attr}=", nil)
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
      end
      describe 'when there is both an issue_date and an expiration_date' do
        let(:issue_date) { today + rand(0..7).days }
        before { subject.issue_date = issue_date }

        it 'does not add an error if the issue_date occurs before the expiration_date' do
          subject.expiration_date = issue_date + rand(1..30).days
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
        it 'adds an error if the expiration_date occurs before the issue date' do
          subject.expiration_date = issue_date - rand(1..30).days
          expect(subject.errors).to receive(:add).with(:expiration_date, :before_issue_date)
          call_validator
        end
        it 'adds an error if the issue_date and the expiration_date occur on the same day' do
          subject.expiration_date = issue_date
          expect(subject.errors).to receive(:add).with(:expiration_date, :before_issue_date)
          call_validator
        end
      end
    end

    describe '`issue_date_within_range`' do
      let(:call_validator) { subject.send(:issue_date_within_range) }
      before { allow(subject).to receive(:date_within_range) }

      it 'does not add an error if there is no issue_date' do
        subject.issue_date = nil
        expect(subject.errors).not_to receive(:add)
        call_validator
      end
      describe 'when there is an issue_date' do
        let(:issue_date) { today + rand(0..7).days }
        before { subject.issue_date = issue_date }

        it 'calls `date_within_range`' do
          expect(subject).to receive(:date_within_range).with(issue_date, described_class::ISSUE_MAX_DATE_RESTRICTION)
          call_validator
        end
        it 'does not add an error if `date_within_range` returns true' do
          allow(subject).to receive(:date_within_range).and_return(true)
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
        it 'adds an error if `date_within_range` returns false' do
          allow(subject).to receive(:date_within_range).and_return(false)
          expect(subject.errors).to receive(:add).with(:issue_date, :invalid)
          call_validator
        end
      end
    end

    describe '`expiration_date_within_range`' do
      let(:call_validator) { subject.send(:expiration_date_within_range) }
      before { allow(subject).to receive(:date_within_range) }

      it 'does not add an error if there is no expiration_date' do
        subject.expiration_date = nil
        expect(subject.errors).not_to receive(:add)
        call_validator
      end
      describe 'when there is an expiration_date' do
        let(:expiration_date) { today + rand(0..7).days }
        before { subject.expiration_date = expiration_date }

        it 'calls `date_within_range`' do
          expect(subject).to receive(:date_within_range).with(expiration_date, described_class::EXPIRATION_MAX_DATE_RESTRICTION)
          call_validator
        end
        it 'does not add an error if `date_within_range` returns true' do
          allow(subject).to receive(:date_within_range).and_return(true)
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
        it 'adds an error if `date_within_range` returns false' do
          allow(subject).to receive(:date_within_range).and_return(false)
          expect(subject.errors).to receive(:add).with(:expiration_date, :invalid)
          call_validator
        end
      end
    end
  end

  describe 'attributes' do
    let(:attr_value) { double('some value') }
    before do
      allow(attr_value).to receive(:gsub).and_return(attr_value)
      allow(attr_value).to receive(:to_i).and_return(attr_value)
    end
    [:lc_number, :beneficiary_name, :beneficiary_address, :amount, :issue_date, :expiration_date].each do |attr|
      it "has an accessible `#{attr}` attribute" do
        subject.send(:"#{attr}=", attr_value)
        expect(subject.send(attr)).to eq(attr_value)
      end
    end
    [:issuance_fee, :maintenance_fee].each do |attr|
      it "has a `#{attr}` attribute that can be read" do
        expect(subject.send(attr)).not_to be nil
      end
      it "has a `#{attr}` attribute that cannot be written" do
        expect(subject.respond_to?(:"#{attr}=")).to be false
      end
    end
  end

  describe 'initialization' do
    let(:issue_date) { today + rand(0..7).days }
    let(:new_loc) { LetterOfCredit.new }
    let(:request) { double('request') }

    describe 'when a request arg is passed' do
      let(:new_loc) { LetterOfCredit.new(request) }
      subject { described_class.new(request) }
      it 'sets `request` to the passed arg' do
        expect(new_loc.request).to eq(request)
      end
      it 'creates a new instance of the CalendarService with the passed request arg' do
        expect(CalendarService).to receive(:new).with(request).and_return(calendar_service)
        new_loc
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
      it 'creates a new instance of the CalendarService with the passed request arg' do
        expect(CalendarService).to receive(:new).with(request).and_return(calendar_service)
        new_loc
      end
    end
    it "sets `issuance_fee` to `#{described_class::DEFAULT_ISSUANCE_FEE}`" do
      expect(subject.issuance_fee).to eq(described_class::DEFAULT_ISSUANCE_FEE)
    end
    it "sets `maintenance_fee` to `#{described_class::DEFAULT_MAINTENANCE_FEE}`" do
      expect(subject.maintenance_fee).to eq(described_class::DEFAULT_MAINTENANCE_FEE)
    end
    describe 'initial `issue_date` value' do
      it 'calls `find_next_business_day` with today and a 1.day step' do
        expect(calendar_service).to receive(:find_next_business_day).with(today, 1.day)
        new_loc
      end
      it 'sets `issue_date` to the result of `find_next_business_day`' do
        allow(calendar_service).to receive(:find_next_business_day).with(today, 1.day).and_return(issue_date)
        expect(subject.issue_date).to eq(issue_date)
      end
    end
    describe 'initial `expiration_date` value' do
      before { allow(calendar_service).to receive(:find_next_business_day).with(today, 1.day).and_return(issue_date) }
      it 'calls `find_next_business_day` with one year from the issue_date and a 1.day step' do
        expect(calendar_service).to receive(:find_next_business_day).with(issue_date + 1.year, 1.day)
        new_loc
      end
      it 'sets `expiration_date` to the result of `find_next_business_day`' do
        expiration_date = instance_double(Date)
        allow(calendar_service).to receive(:find_next_business_day).with(issue_date + 1.year, 1.day).and_return(expiration_date)
        expect(subject.expiration_date).to eq(expiration_date)
      end
    end
  end

  describe 'class methods' do
    describe '`from_hash`' do
      let(:hash) { instance_double(Hash) }
      let(:loc) { instance_double(LetterOfCredit, :attributes= => nil) }
      let(:call_method) { LetterOfCredit.from_hash(hash) }

      it 'creates a new `LetterOfCredit`' do
        expect(LetterOfCredit).to receive(:new).and_return(loc)
        call_method
      end
      it 'calls `attributes=` with the passed hash' do
        allow(LetterOfCredit).to receive(:new).and_return(loc)
        expect(loc).to receive(:attributes=).with(hash)
        call_method
      end
      it 'returns the `LetterOfCredit`' do
        expect(LetterOfCredit.from_hash({})).to be_a(LetterOfCredit)
      end
    end
  end

  describe 'instance methods' do
    describe '`attributes=`' do
      read_only_attrs = [:issuance_fee, :maintenance_fee]
      date_attrs = [:issue_date, :expiration_date]
      custom_attrs = [:amount, :beneficiary_name]
      serialization_exclude_attrs = [:request]
      let(:hash) { {} }
      let(:value) { double('some value') }
      let(:call_method) { subject.send(:attributes=, hash) }

      (described_class::ACCESSIBLE_ATTRS - date_attrs - read_only_attrs - custom_attrs - serialization_exclude_attrs).each do |key|
        it "assigns the value found under `#{key}` to the attribute `#{key}`" do
          hash[key.to_s] = value
          call_method
          expect(subject.send(key)).to be(value)
        end
      end
      custom_attrs.each do |key|
        it "calls `#{key}=` with the value for `#{key}`" do
          expect(subject).to receive(:"#{key}=").with(value)
          hash[key] = value
          call_method
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
      read_only_attrs.each do |key|
        it "ignores the `#{key}` read-only attribute if it is in the passed hash" do
          hash[key.to_s] = value
          call_method
          expect(subject.send(key)).not_to be(value)
        end
      end
      serialization_exclude_attrs.each do |attr|
        it 'raises an error if it encounters an excluded attribute' do
          hash[attr] = double('A Value')
          expect{call_method}.to raise_error(ArgumentError, "illegal attribute: #{attr}")
        end
      end
      it 'raises an exception if the hash contains keys that are not `LetterOfRequest` attributes' do
        hash[:foo] = 'bar'
        expect{call_method}.to raise_error(ArgumentError, "unknown attribute: foo")
      end
    end

    describe '`amount=`' do
      describe 'when the amount is an object that responds to the `gsub` method' do
        let(:amount) { double('amount', gsub: nil, to_i: nil) }

        it 'gsubs out commas' do
          expect(amount).to receive(:gsub).with(',', '')
          subject.amount = amount
        end
        it 'turns the gsubbed value into an integer' do
          allow(amount).to receive(:gsub).and_return(amount)
          expect(amount).to receive(:to_i)
          subject.amount = amount
        end
        it 'assigns the integer value to the `amount` attribute' do
          allow(amount).to receive(:gsub).and_return(amount)
          allow(amount).to receive(:to_i).and_return(amount)
          subject.amount = amount
          expect(subject.amount).to eq(amount)
        end
      end
      describe 'when the amount is an object that does not respond to the `gsub` method' do
        let(:amount) { double('amount', to_i: nil) }

        it 'turns the amount into an integer' do
          expect(amount).to receive(:to_i)
          subject.amount = amount
        end
        it 'assigns the integer value to the `amount` attribute' do
          allow(amount).to receive(:to_i).and_return(amount)
          subject.amount = amount
          expect(subject.amount).to eq(amount)
        end
      end
      it 'assigns `amount` nil if it is passed nil' do
        subject.amount = rand(100..99999)
        subject.amount = nil
        expect(subject.amount).to be nil
      end
    end

    describe '`beneficiary_name=`' do
      let(:beneficiaries_service) { instance_double(BeneficiariesService, all: []) }
      let(:beneficiary_name) { SecureRandom.hex }
      let(:request) { double('request') }
      subject { described_class.new(request) }
      let(:call_method) { subject.beneficiary_name = beneficiary_name }

      before do
        allow(BeneficiariesService).to receive(:new).and_return(beneficiaries_service)
      end

      it 'creates a new instance of the BeneficiaryService with the request attr' do
        expect(BeneficiariesService).to receive(:new).with(request).and_return(beneficiaries_service)
        call_method
      end
      it 'fetches a list of all beneficiaries' do
        expect(beneficiaries_service).to receive(:all)
        call_method
      end
      describe 'when the beneficiary is found in the list of all beneficiaries' do
        let(:beneficiary_address) { SecureRandom.hex }

        before do
          allow(beneficiaries_service).to receive(:all).and_return([{
            name: beneficiary_name,
            address: beneficiary_address
          }])
        end
        it 'sets the `beneficiary_address` to the address corresponding to the `beneficiary_name`' do
          call_method
          expect(subject.beneficiary_address).to eq(beneficiary_address)
        end
      end
      it 'sets @beneficiary_name to the passed name' do
        call_method
        expect(subject.beneficiary_name).to eq(beneficiary_name)
      end
    end
  end

  describe 'private methods' do
    describe '`date_within_range`' do
      let(:date) { today + rand(0..7).days }
      let(:date_restriction) { rand(1..30).days }
      let(:request) { double('request') }
      subject { described_class.new(request) }
      let(:call_method) { subject.send(:date_within_range, date, date_restriction) }
      it 'creates a new CalendarService instance with the request' do
        expect(CalendarService).to receive(:new).with(request).and_return(calendar_service)
        call_method
      end
      it 'calls `holidays` on the CalendarService instance with today as the min_date arg' do
        expect(calendar_service).to receive(:holidays).with(today, anything).and_return([])
        call_method
      end
      it 'calls `holidays` on the CalendarService instance with today plus the max_date_restriction as the max_date arg' do
        expect(calendar_service).to receive(:holidays).with(anything, today + date_restriction).and_return([])
        call_method
      end
      it 'returns false if the passed date is a Sunday' do
        date = instance_double(Date, sunday?: true, :+ => nil)
        expect(subject.send(:date_within_range, date, date_restriction)).to be false
      end
      describe 'when the passed date is not a Sunday' do
        let(:date) { instance_double(Date, sunday?: false, :+ => nil) }

        it 'returns false if the passed date is a Saturday' do
          allow(date).to receive(:saturday?).and_return(true)
          expect(call_method).to be false
        end

        describe 'when the passed date is not a Saturday' do
          before { allow(date).to receive(:saturday?).and_return(false) }
          it 'returns false if the date is a holiday' do
            allow(calendar_service).to receive(:holidays).and_return([date])
            expect(call_method).to be false
          end

          describe 'when the passed date is not a holiday' do
            it 'returns false if the date occurs before today' do
              allow(date).to receive(:>=).with(today).and_return(false)
              expect(call_method).to be false
            end

            describe 'when the date is today or later' do
              let(:max_date) { today + date_restriction }
              before { allow(date).to receive(:>=).with(today).and_return(true) }

              it 'returns false if the date occurs after today plus the max date restriction' do
                allow(date).to receive(:<=).with(max_date).and_return(false)
                expect(call_method).to be false
              end
              it 'returns true if the date occurs on today plus the max date restriction or before that date' do
                allow(date).to receive(:<=).with(max_date).and_return(true)
                expect(call_method).to be true
              end
            end
          end
        end
      end
    end
  end
end