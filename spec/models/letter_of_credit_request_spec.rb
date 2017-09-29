require 'rails_helper'

RSpec.describe LetterOfCreditRequest, :type => :model do
  let(:today) { Time.zone.today }
  let(:calendar_service) { instance_double(CalendarService, holidays: [], find_next_business_day: today) }
  let(:beneficiary_service) { instance_double(BeneficiariesService, beneficiaries: []) }
  let(:member_id) { rand(1000..9999) }

  before do
    allow(CalendarService).to receive(:new).and_return(calendar_service)
    allow(BeneficiariesService).to receive(:new).and_return(beneficiary_service)
    allow(Time.zone).to receive(:today).and_return(today)
  end

  subject { described_class.new(member_id) }

  describe 'validations' do
    before do
      subject.instance_variable_set('@standard_borrowing_capacity', 0)
      subject.instance_variable_set('@max_term', 0)
      subject.instance_variable_set('@remaining_financing_available', 0)
    end
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
    [:issue_date_must_come_before_expiration_date,
     :issue_date_within_range,
     :expiration_date_within_range,
     :amount_does_not_exceed_borrowing_capacity,
     :amount_does_not_exceed_financing_availability,
     :expiration_date_before_max_term,
     :amended_expiration_on_or_after_original_expiration,
     :amended_amount_equal_or_greater_than_original_amount,
     :amendment_date_not_prior_to_current_date
    ].each do |method|
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

        it 'calls `date_within_range` with the issue_date' do
          expect(subject).to receive(:date_within_range).with(issue_date, anything)
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
        it 'calls `past_issue_date_restriction_window?`' do
          expect(subject).to receive(:past_issue_date_restriction_window?)
          call_validator
        end
        context 'when `past_issue_date_restriction_window?` returns true' do
          before { allow(subject).to receive(:past_issue_date_restriction_window?).and_return(true) }
          it 'calls `date_within_range` with the ISSUE_MAX_DATE_RESTRICTION plus tomorrow' do
            expect(subject).to receive(:date_within_range).with(anything, (today + 1.day) + described_class::ISSUE_MAX_DATE_RESTRICTION)
            call_validator
          end
        end
        context 'when `past_issue_date_restriction_window?` returns false' do
          before { allow(subject).to receive(:past_issue_date_restriction_window?).and_return(false) }
          it 'calls `date_within_range` with the ISSUE_MAX_DATE_RESTRICTION plus today' do
            expect(subject).to receive(:date_within_range).with(anything, today + described_class::ISSUE_MAX_DATE_RESTRICTION)
            call_validator
          end
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

        it 'calls `date_within_range` with the expiration_date' do
          expect(subject).to receive(:date_within_range).with(expiration_date, anything)
          call_validator
        end
        context 'when there is an issue_date' do
          let(:issue_date) { today + rand(0..7).days }
          before { subject.issue_date = issue_date }
          it 'calls `date_within_range` with the EXPIRATION_MAX_DATE_RESTRICTION plus the issue_date' do
            expect(subject).to receive(:date_within_range).with(anything, issue_date + described_class::EXPIRATION_MAX_DATE_RESTRICTION)
            call_validator
          end
        end
        context 'when there is not an issue_date' do
          it 'calls `date_within_range` with the EXPIRATION_MAX_DATE_RESTRICTION plus today' do
            expect(subject).to receive(:date_within_range).with(anything, today + described_class::EXPIRATION_MAX_DATE_RESTRICTION)
            call_validator
          end
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

    describe '`amended_expiration_on_or_after_original_expiration`' do
      let(:call_validator) { subject.send(:amended_expiration_on_or_after_original_expiration) }

      [:expiration_date, :amended_expiration_date].each do |attr|
        it "does not add an error if there is no `#{attr}`" do
          subject.send(:"#{attr}=", nil)
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
      end

      describe 'when there is both an expiration_date and an amended_expiration_date' do
        let(:expiration_date) { today + rand(12..18).months }
        before { subject.expiration_date = expiration_date }

        it 'does not add an error if the amended_expiration_date occurs on or after the expiration_date' do
          subject.amended_expiration_date = expiration_date + rand(0..30).days
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
        it 'adds an error if the amended_expiration_date occurs prior to expiration_date date' do
          subject.amended_expiration_date = expiration_date - rand(1..30).days
          expect(subject.errors).to receive(:add).with(:amended_expiration_date, :amended_exp_date_prior_to_original)
          call_validator
        end
      end
    end

    describe '`amended_amount_equal_or_greater_than_original_amount`' do
      let(:call_validator) { subject.send(:amended_amount_equal_or_greater_than_original_amount) }

      [:amount, :amended_amount].each do |attr|
        it "does not add an error if there is no `#{attr}`" do
          subject.send(:"#{attr}=", nil)
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
      end

      describe 'when there is both an amount and an amended_amount' do
        let(:amount) { rand(100000 .. 1000000)}
        before { subject.amount = amount }
        it 'does not add an error if the amended_amount is equal to or greater than the original amount' do
          subject.amended_amount = amount + rand(0..1000000)
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
        it 'adds an error if the amended_amount is less than the original amount' do
          subject.amended_amount = amount - rand(1..10000)
          expect(subject.errors).to receive(:add).with(:amended_amount, :amended_amount_less_than_original_amount)
          call_validator
        end
      end
    end

    describe '`amendment_date_not_prior_to_current_date`' do
      let(:call_validator) { subject.send(:amendment_date_not_prior_to_current_date) }

      it 'does not add an error if there is no amendment_date' do
        subject.amendment_date = nil
        expect(subject.errors).not_to receive(:add)
        call_validator
      end
      it 'adds an error if the expiration_date occurs before the issue date' do
        subject.amendment_date = today - 1.days
        expect(subject.errors).to receive(:add).with(:amendment_date, :amendment_date_prior_to_current_date)
        call_validator
      end
    end

    describe '`amount_does_not_exceed_borrowing_capacity`' do
      let(:today) { Time.zone.today }
      let(:remaining_bc) { rand(10000..9999999) }
      let(:call_validator) { subject.send(:amount_does_not_exceed_borrowing_capacity) }

      before do
        allow(Time.zone).to receive(:today).and_return(today)
        allow(subject).to receive(:fetch_member_profile) { subject.instance_variable_set('@standard_borrowing_capacity', remaining_bc) }
      end

      it 'calls `fetch_member_profile`' do
        expect(subject).to receive(:fetch_member_profile) { subject.instance_variable_set('@standard_borrowing_capacity', remaining_bc) }
        call_validator
      end
      describe 'when there is no amount value' do
        it 'does not add an error' do
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
      end
      describe 'when the amount is less than the remaining standard borrowing capacity' do
        it 'does not add an error' do
          subject.amount = remaining_bc - rand(100..9999)
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
      end
      describe 'when the amount is equal to the remaining standard borrowing capacity' do
        it 'does not add an error' do
          subject.amount = remaining_bc
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
      end
      describe 'when the amount is greater than the remaining standard borrowing capacity' do
        before { subject.amount = remaining_bc + rand(1..100000) }
        it 'adds an error' do
          expect(subject.errors).to receive(:add).with(:amount, :exceeds_borrowing_capacity)
          call_validator
        end
      end
    end

    describe '`expiration_date_before_max_term`' do
      let(:issue_date) { today }
      let(:expiration_date) { today + rand(12..36).months }
      let(:call_validator) { subject.send(:expiration_date_before_max_term) }
      context 'when there is an issue_date' do
        before do
          subject.issue_date = issue_date
          subject.expiration_date = nil
        end
        it 'does not add an error if there is no expiration_date' do
          expect(subject.errors).not_to receive(:add).with(:expiration_date, :after_max_term)
          call_validator
        end
      end
      context 'when there is an expiration_date' do
        before do
          subject.expiration_date = expiration_date
          subject.issue_date = nil
        end
        it 'does not add an error if there is no issue_date' do
          expect(subject.errors).not_to receive(:add).with(:expiration_date, :after_max_term)
          call_validator
        end
      end
      context 'when there is both an issue_date and an expiration_date' do
        let(:ducktyped_date) { double('date') }
        let(:max_term) { double('max term', months: 12.months) }
        before do
          subject.expiration_date = expiration_date
          subject.issue_date = issue_date
          allow(subject).to receive(:fetch_member_profile) { subject.instance_variable_set('@max_term', max_term) }
        end
        it 'calls `fetch_member_profile`' do
          expect(subject).to receive(:fetch_member_profile) { subject.instance_variable_set('@max_term', max_term) }
          call_validator
        end
        it 'ensures the expiration date is a date' do
          subject.expiration_date = ducktyped_date
          expect(ducktyped_date).to receive(:to_date).and_return(expiration_date)
          call_validator
        end
        it 'ensures the issue date is a date' do
          subject.issue_date = ducktyped_date
          expect(ducktyped_date).to receive(:to_date).and_return(expiration_date)
          call_validator
        end
        it 'does not add an error if the expiration date is less than max_term number of months from the issue_date' do
          subject.expiration_date = (issue_date + max_term.months) - 1.day
          expect(subject.errors).not_to receive(:add).with(:expiration_date, :after_max_term)
          call_validator
        end
        it 'does not add an error if the expiration date is equal to the max_term number of months from the issue_date' do
          subject.expiration_date = issue_date + max_term.months
          expect(subject.errors).not_to receive(:add).with(:expiration_date, :after_max_term)
          call_validator
        end
        it 'adds an error if the expiration date is greater than the max_term number of months from the issue_date' do
          subject.expiration_date = (issue_date + max_term.months) + 1.day
          expect(subject.errors).to receive(:add).with(:expiration_date, :after_max_term)
          call_validator
        end
      end
    end

    describe '`amended_expiration_date_before_max_term`' do
      let(:issue_date) { today }
      let(:expiration_date) { today + rand(12..36).months }
      let(:amended_expiration_date) { today + rand(12..36).months}
      let(:call_validator) { subject.send(:amended_expiration_date_before_max_term) }

      let(:ducktyped_date) { double('date') }
      let(:max_term) { double('max term', months: 12.months) }
      before do
        subject.amended_expiration_date = expiration_date + rand(0..30).days
        subject.issue_date = issue_date
        allow(subject).to receive(:fetch_member_profile) { subject.instance_variable_set('@max_term', max_term) }
      end
      it 'calls `fetch_member_profile`' do
        expect(subject).to receive(:fetch_member_profile) { subject.instance_variable_set('@max_term', max_term) }
        call_validator
      end
      it 'ensures the amended expiration date is a date' do
        subject.amended_expiration_date = ducktyped_date
        expect(ducktyped_date).to receive(:to_date).and_return(amended_expiration_date)
        call_validator
      end
      it 'ensures the issue date is a date' do
        subject.issue_date = ducktyped_date
        expect(ducktyped_date).to receive(:to_date).and_return(issue_date)
        call_validator
      end
      it 'does not add an error if the expiration date is less than max_term number of months from the issue_date' do
        subject.amended_expiration_date = (issue_date + max_term.months) - 1.day
        expect(subject.errors).not_to receive(:add).with(:amended_expiration_date, :after_max_term)
        call_validator
      end
      it 'does not add an error if the expiration date is equal to the max_term number of months from the issue_date' do
        subject.amended_expiration_date = issue_date + max_term.months
        expect(subject.errors).not_to receive(:add).with(:amended_expiration_date, :after_max_term)
        call_validator
      end
      it 'adds an error if the expiration date is greater than the max_term number of months from the issue_date' do
        subject.amended_expiration_date = (issue_date + max_term.months) + 1.day
        expect(subject.errors).to receive(:add).with(:amended_expiration_date, :after_max_term)
        call_validator
      end
    end

    describe '`amount_does_not_exceed_financing_availability`' do
      let(:today) { Time.zone.today }
      let(:remaining_financing_available) { rand(10000..9999999) }
      let(:call_validator) { subject.send(:amount_does_not_exceed_financing_availability) }

      before do
        allow(Time.zone).to receive(:today).and_return(today)
        allow(subject).to receive(:fetch_member_profile) { subject.instance_variable_set('@remaining_financing_available', remaining_financing_available) }
      end

      it 'calls `fetch_member_profile`' do
        expect(subject).to receive(:fetch_member_profile) { subject.instance_variable_set('@remaining_financing_available', remaining_financing_available) }
        call_validator
      end
      describe 'when there is no amount value' do
        it 'does not add an error' do
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
      end
      describe 'when the amount is less than the remaining financing available' do
        it 'does not add an error' do
          subject.amount = remaining_financing_available - rand(100..9999)
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
      end
      describe 'when the amount is equal to the remaining financing available' do
        it 'does not add an error' do
          subject.amount = remaining_financing_available
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
      end
      describe 'when the amount is greater than the remaining financing available' do
        before { subject.amount = remaining_financing_available + rand(1..100000) }
        it 'adds an error' do
          expect(subject.errors).to receive(:add).with(:amount, :exceeds_financing_availability)
          call_validator
        end
      end
    end

    describe '`issue_date_valid_for_today`' do
      let(:call_validator) { subject.send(:issue_date_valid_for_today) }
      it 'is not called as a validator if there is no issue date' do
        subject.issue_date = nil
        expect(subject).not_to receive(:issue_date_valid_for_today)
        subject.valid?
      end
      it 'is not called as a validator if the issue date is not today' do
        subject.issue_date = today + rand(1..6).days
        expect(subject).not_to receive(:issue_date_valid_for_today)
        subject.valid?
      end
      context 'when the issue date is today' do
        before { subject.issue_date = today }

        it 'is called as a validator' do
          expect(subject).to receive(:issue_date_valid_for_today)
          subject.valid?
        end
        it 'calls `past_issue_date_restriction_window?`' do
          expect(subject).to receive(:past_issue_date_restriction_window?)
          call_validator
        end
        it 'adds an error if `past_issue_date_restriction_window?` returns true' do
          allow(subject).to receive(:past_issue_date_restriction_window?).and_return(true)
          expect(subject.errors).to receive(:add).with(:issue_date, :no_longer_valid)
          call_validator
        end
        it 'does not add an error if `past_issue_date_restriction_window?` returns false' do
          allow(subject).to receive(:past_issue_date_restriction_window?).and_return(false)
          expect(subject.errors).not_to receive(:add)
          call_validator
        end
      end
    end
  end

  describe 'initialization' do
    let(:issue_date) { today + rand(0..7).days }
    let(:new_loc) { LetterOfCreditRequest.new(member_id) }
    let(:now) { instance_double(Time, :> => nil) }
    let(:parsed_time) { instance_double(Time) }
    let(:request) { double('request') }

    before do
      allow(Time.zone).to receive(:now).and_return(now)
      allow(Time.zone).to receive(:parse).and_return(parsed_time)
    end

    describe 'when a request arg is passed' do
      let(:new_loc) { LetterOfCreditRequest.new(member_id, request) }
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
    it 'sets `member_id` to the passed member_id arg' do
      expect(new_loc.member_id).to eq(member_id)
    end
    it "sets `issuance_fee` to `#{described_class::DEFAULT_ISSUANCE_FEE}`" do
      expect(subject.issuance_fee).to eq(described_class::DEFAULT_ISSUANCE_FEE)
    end
    it "sets `maintenance_fee` to `#{described_class::DEFAULT_MAINTENANCE_FEE}`" do
      expect(subject.maintenance_fee).to eq(described_class::DEFAULT_MAINTENANCE_FEE)
    end
    describe 'initial `issue_date` value' do
      it 'parses the LetterOfCreditRequest::ISSUE_DATE_TIME_RESTRICTION to create an ActiveRecord::TimeWithZone object' do
        expect(Time.zone).to receive(:parse).with(LetterOfCreditRequest::ISSUE_DATE_TIME_RESTRICTION).and_return(parsed_time)
        new_loc
      end
      it 'checks to see if the current time is greater than the time restriction' do
        expect(now).to receive(:>).with(parsed_time)
        new_loc
      end
      shared_examples 'it sets `issue_date` based on `find_next_business_day`' do |day|
        let(:start_date) { day == :today ? today : today + 1.day }
        it "calls `find_next_business_day` with #{day} and a 1.day step" do
          expect(calendar_service).to receive(:find_next_business_day).with(start_date, 1.day)
          new_loc
        end
        it 'sets `issue_date` to the result of `find_next_business_day`' do
          allow(calendar_service).to receive(:find_next_business_day).with(start_date, 1.day).and_return(issue_date)
          expect(subject.issue_date).to eq(issue_date)
        end
      end
      context 'when it is before the ISSUE_DATE_TIME_RESTRICTION' do
        before { allow(now).to receive(:>).and_return(false) }
        it_behaves_like 'it sets `issue_date` based on `find_next_business_day`', :today
      end
      context 'when it is after the ISSUE_DATE_TIME_RESTRICTION' do
        before { allow(now).to receive(:>).and_return(true) }
        it_behaves_like 'it sets `issue_date` based on `find_next_business_day`', :tomorrow
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
    describe '`from_json`' do
      let(:json) { double('some JSON') }
      let(:request) { double('request') }
      let(:loc) { instance_double(LetterOfCreditRequest, from_json: nil) }
      let(:call_method) { LetterOfCreditRequest.from_json(json, request) }

      before { allow(LetterOfCreditRequest).to receive(:new).and_return(loc) }

      it 'creates a new `LetterOfCreditRequest`' do
        expect(LetterOfCreditRequest).to receive(:new).and_return(loc)
        call_method
      end
      it 'calls `from_json` with the passed json' do
        expect(loc).to receive(:from_json).with(json)
        call_method
      end
      it 'returns the `LetterOfCreditRequest`' do
        allow(loc).to receive(:from_json).and_return(loc)
        expect(call_method).to eq(loc)
      end
    end

    describe '`policy_class`' do
      it 'returns the LettersOfCreditPolicy class' do
        expect(described_class.policy_class).to eq(LettersOfCreditPolicy)
      end
    end

    describe '`find_by_lc_number`' do
      let(:request) { double('request') }
      let(:lc_number) { SecureRandom.hex }
      let(:loc) { LetterOfCreditRequest.find_by_lc_number(member_id, lc_number, request) }
      let(:lc_details) { instance_double(Hash, :[] => nil) }
      let(:amendment_date) { Time.zone.today}
      let(:now) { instance_double(Time, :> => nil) }
      let(:parsed_time) { instance_double(Time) }
      let(:letter_of_credit_request) { instance_double( LetterOfCreditRequest,
                                                        'beneficiary_name=': nil,
                                                        'amount=': nil,
                                                        'amended_amount=': nil,
                                                        'issue_date=': nil,
                                                        'expiration_date=': nil,
                                                        'amended_expiration_date=': nil,
                                                        'amendment_date=': nil) }
      let(:member_balance_service) { instance_double(MemberBalanceService, letter_of_credit: lc_details)}
      before do
        allow(Time.zone).to receive(:now).and_return(now)
        allow(Time.zone).to receive(:parse).and_return(parsed_time)
        allow(LetterOfCreditRequest).to receive(:new).with(member_id, request).and_return(letter_of_credit_request)
        allow(MemberBalanceService).to receive(:new).with(member_id, request).and_return(member_balance_service)
        allow(member_balance_service).to receive(:letter_of_credit).with(lc_number).and_return(lc_details)
      end
      it 'creates a new `LetterOfCreditRequest` instance' do
        expect(LetterOfCreditRequest).to receive(:new).with(member_id, request).and_return(letter_of_credit_request)
        loc
      end
      it 'creates a new instance of the `CalendarService`' do
        expect(CalendarService).to receive(:new).and_return(calendar_service)
        loc
      end
      it 'creates a new instance of the `MemberBalanceService`' do
        expect(MemberBalanceService).to receive(:new).with(member_id, request).and_return(member_balance_service)
        loc
      end
      it 'calls `letter_of_credit` on `member_balances`' do
        expect(member_balance_service).to receive(:letter_of_credit).with(lc_number)
        loc
      end
      it 'assigns `beneficiary_name`' do
        beneficiary = SecureRandom.hex
        allow(lc_details).to receive(:[]).with(:beneficiary).and_return(beneficiary)
        expect(letter_of_credit_request).to receive(:'beneficiary_name=').with(beneficiary)
        loc
      end
      it 'assigns `amount`' do
        amount = rand(100000..999999)
        allow(lc_details).to receive(:[]).with(:current_par).and_return(amount)
        expect(letter_of_credit_request).to receive(:'amount=').with(amount)
        loc
      end
      it 'assigns `amended_amount`' do
        amended_amount = rand(100000..999999)
        allow(lc_details).to receive(:[]).with(:current_par).and_return(amended_amount)
        expect(letter_of_credit_request).to receive(:'amended_amount=').with(amended_amount)
        loc
      end
      it 'assigns `issue_date`' do
        issue_date = SecureRandom.hex
        allow(lc_details).to receive(:[]).with(:trade_date).and_return(issue_date)
        expect(letter_of_credit_request).to receive(:'issue_date=').with(issue_date)
        loc
      end
      it 'assigns `expiration_date`' do
        expiration_date = SecureRandom.hex
        allow(lc_details).to receive(:[]).with(:maturity_date).and_return(expiration_date)
        expect(letter_of_credit_request).to receive(:'expiration_date=').with(expiration_date)
        loc
      end
      it 'assigns `amended_expiration_date`' do
        amended_expiration_date = SecureRandom.hex
        allow(lc_details).to receive(:[]).with(:maturity_date).and_return(amended_expiration_date)
        expect(letter_of_credit_request).to receive(:'amended_expiration_date=').with(amended_expiration_date)
        loc
      end
      describe 'initial asigment of `amendment_date`' do
        it 'parses the LetterOfCreditRequest::ISSUE_DATE_TIME_RESTRICTION to create an ActiveRecord::TimeWithZone object' do
          expect(Time.zone).to receive(:parse).with(LetterOfCreditRequest::AMENDMENT_DATE_TIME_RESTRICTION).and_return(parsed_time)
          loc
        end
        it 'checks to see if the current time is greater than the time restriction' do
          expect(now).to receive(:>).with(parsed_time)
          loc
        end
        shared_examples 'it sets `amendment_date` based on `find_next_business_day`' do |day|
          let(:start_date) { day == :today ? today : today + 1.day }
          it "calls `find_next_business_day` with #{day} and a 1.day step" do
            expect(calendar_service).to receive(:find_next_business_day).with(start_date, 1.day)
            loc
          end
          it 'sets `amendment_date` to the result of `find_next_business_day`' do
            allow(calendar_service).to receive(:find_next_business_day).with(start_date, 1.day).and_return(issue_date)
            expect(subject.issue_date).to eq(amendment_date)
          end
        end
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
      read_only_attrs = [:issuance_fee, :maintenance_fee, :amendment_fee, :request, :lc_number, :id, :member_id]
      date_attrs = [:issue_date, :expiration_date, :amended_expiration_date, :amendment_date, :created_at]
      custom_attrs = [:amount, :beneficiary_name, :attention, :amended_amount]
      serialization_exclude_attrs = [:request]
      let(:hash) { {} }
      let(:value) { double('some value') }
      let(:call_method) { subject.send(:attributes=, hash) }

      (described_class::ACCESSIBLE_ATTRS + read_only_attrs - date_attrs - custom_attrs - serialization_exclude_attrs).each do |key|
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
          datefied_value = instance_double(ActiveSupport::TimeWithZone)
          allow(Time.zone).to receive(:parse).and_call_original
          allow(Time.zone).to receive(:parse).with(value).and_return(datefied_value)
          hash[key.to_s] = value
          call_method
          expect(subject.send(key)).to be(datefied_value)
        end
        it "assigns nil to the attribute `#{key}` if the value is nil" do
          hash[key.to_s] = nil
          call_method
          expect(subject.send(key)).to be(nil)
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

    describe '`amended_amount=`' do
      describe 'when the amended_amount is an object that responds to the `gsub` method' do
        let(:amended_amount) { double('amended_amount', gsub: nil, to_i: nil) }

        it 'gsubs out commas' do
          expect(amended_amount).to receive(:gsub).with(',', '')
          subject.amended_amount = amended_amount
        end
        it 'turns the gsubbed value into an integer' do
          allow(amended_amount).to receive(:gsub).and_return(amended_amount)
          expect(amended_amount).to receive(:to_i)
          subject.amended_amount = amended_amount
        end
        it 'assigns the integer value to the `amount` attribute' do
          allow(amended_amount).to receive(:gsub).and_return(amended_amount)
          allow(amended_amount).to receive(:to_i).and_return(amended_amount)
          subject.amended_amount = amended_amount
          expect(subject.amended_amount).to eq(amended_amount)
        end
      end
      describe 'when the amended_amount is an object that does not respond to the `gsub` method' do
        let(:amended_amount) { double('amended_amount', to_i: nil) }

        it 'turns the amended_amount into an integer' do
          expect(amended_amount).to receive(:to_i)
          subject.amended_amount = amended_amount
        end
        it 'assigns the integer value to the `amended_amount` attribute' do
          allow(amended_amount).to receive(:to_i).and_return(amended_amount)
          subject.amended_amount = amended_amount
          expect(subject.amended_amount).to eq(amended_amount)
        end
      end
      it 'assigns `amended_amount` nil if it is passed nil' do
        subject.amended_amount = rand(100..99999)
        subject.amended_amount = nil
        expect(subject.amended_amount).to be nil
      end
    end

    describe '`beneficiary_name=`' do
      let(:beneficiaries_service) { instance_double(BeneficiariesService, beneficiaries: []) }
      let(:beneficiary_name) { SecureRandom.hex }
      let(:request) { double('request') }
      subject { described_class.new(member_id, request) }
      let(:call_method) { subject.beneficiary_name = beneficiary_name }

      before do
        allow(BeneficiariesService).to receive(:new).and_return(beneficiaries_service)
      end

      it 'creates a new instance of the BeneficiaryService with the request attr' do
        expect(BeneficiariesService).to receive(:new).with(request).and_return(beneficiaries_service)
        call_method
      end
      it 'fetches a list of all beneficiaries' do
        expect(beneficiaries_service).to receive(:beneficiaries)
        call_method
      end
      describe 'when the beneficiary is found in the list of all beneficiaries' do
        let(:beneficiary_address) { SecureRandom.hex }

        before do
          allow(beneficiaries_service).to receive(:beneficiaries).and_return([{
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

    describe '`execute`' do
      let(:requester_name) { SecureRandom.hex }
      let(:call_method) { subject.execute(requester_name) }

      before { allow(subject).to receive(:set_lc_number) }

      it 'sets `created_by` to the passed requester name' do
        call_method
        expect(subject.created_by).to eq(requester_name)
      end
      it 'sets `created_at` to Time.zone.now' do
        now = instance_double(DateTime)
        allow(Time.zone).to receive(:now).and_return(now)
        call_method
        expect(subject.created_at).to eq(now)
      end
      it 'calls `set_lc_number`' do
        expect(subject).to receive(:set_lc_number)
        call_method
      end
      it 'returns true if `set_lc_number` raises no errors' do
        expect(call_method).to be true
      end
      it 'returns false if `set_lc_number` raises an error' do
        allow(subject).to receive(:set_lc_number).and_raise(StandardError)
        expect(call_method).to be false
      end
    end

    describe '`amend_execute`' do
      let(:requester_name) { SecureRandom.hex }
      let(:call_method) { subject.amend_execute(requester_name) }

      let(:now) { instance_double(Time, :> => nil) }
      let(:parsed_time) { instance_double(Time) }

      before do
        allow(Time.zone).to receive(:now).and_return(now)
        allow(Time.zone).to receive(:parse).and_return(parsed_time)
      end

      it 'sets `created_by` to the passed requester name' do
        call_method
        expect(subject.created_by).to eq(requester_name)
      end
      it 'sets `created_at` to Time.zone.now' do
        call_method
        expect(subject.created_at).to eq(now)
      end
    end

    describe '`owners` method' do
      let(:call_method) { subject.owners }
      it 'returns a Set' do
        expect(call_method).to be_kind_of(Set)
      end
      it 'returns the same object on each call' do
        set = call_method
        expect(call_method).to be(set)
      end
    end

    describe '`standard_borrowing_capacity` method' do
      let(:call_method) { subject.standard_borrowing_capacity }
      it 'returns the `@standard_borrowing_capacity` attribute if already set' do
        existing_value = double('some value')
        subject.instance_variable_set('@standard_borrowing_capacity', existing_value)
        expect(call_method).to eq(existing_value)
      end
      context 'when the `@standard_borrowing_capacity` attribute is not already set' do
        it 'returns nil if there is no @member_profile' do
          expect(call_method).to be nil
        end
        context 'when there is a @member_profile' do
          let(:standard_excess_capacity) { double('excess capacity') }
          let(:member_profile) { {collateral_borrowing_capacity: {standard: {remaining: double('excess bc', to_i: standard_excess_capacity)}} } }
          before { subject.instance_variable_set('@member_profile', member_profile) }
          it 'calls `to_i` on the value of `@member_profile[:collateral_borrowing_capacity][:standard][:remaining]`' do
            expect(member_profile[:collateral_borrowing_capacity][:standard][:remaining]).to receive(:to_i)
            call_method
          end
          it 'returns the `standard_excess_capacity`' do
            expect(call_method).to eq(standard_excess_capacity)
          end
          it 'returns the same object on each call' do
            capacity = call_method
            expect(call_method).to be(capacity)
          end
        end
      end
    end

    describe '`max_term` method' do
      let(:call_method) { subject.max_term }
      it 'returns the `@max_term` attribute if already set' do
        existing_value = double('some value')
        subject.instance_variable_set('@max_term', existing_value)
        expect(call_method).to eq(existing_value)
      end
      context 'when the `@max_term` attribute is not already set' do
        it 'returns nil if there is no @member_profile' do
          expect(call_method).to be nil
        end
        context 'when there is @member_profile' do
          let(:max_term) { double('the maximum term in months') }
          let(:member_profile) { {maximum_term: double('max term', to_i: max_term)} }
          before { subject.instance_variable_set('@member_profile', member_profile) }
          it 'calls `to_i` on the value of `maximum_term` for @member_profile' do
            expect(member_profile[:maximum_term]).to receive(:to_i)
            call_method
          end
          it 'returns the `maximum_term`' do
            expect(call_method).to eq(max_term)
          end
          it 'returns the same object on each call' do
            term = call_method
            expect(call_method).to be(term)
          end
        end
      end
    end

    describe '`remaining_financing_available` method' do
      let(:call_method) { subject.remaining_financing_available }
      it 'returns the `@remaining_financing_available` attribute if already set' do
        existing_value = double('some value')
        subject.instance_variable_set('@remaining_financing_available', existing_value)
        expect(call_method).to eq(existing_value)
      end
      context 'when the `@remaining_financing_available` attribute is not already set' do
        it 'returns nil if there is no @member_profile' do
          expect(call_method).to be nil
        end
        context 'when there is @member_profile' do
          let(:remaining_financing_available) { double('remaining_financing_available') }
          let(:member_profile) { {remaining_financing_available: double('financing available', to_i: remaining_financing_available)} }
          before { subject.instance_variable_set('@member_profile', member_profile) }
          it 'calls `to_i` on the value of `remaining_financing_available` for @member_profile' do
            expect(member_profile[:remaining_financing_available]).to receive(:to_i)
            call_method
          end
          it 'returns the `remaining_financing_available`' do
            expect(call_method).to eq(remaining_financing_available)
          end
          it 'returns the same object on each call' do
            term = call_method
            expect(call_method).to be(term)
          end
        end
      end
    end
  end

  describe 'private methods' do
    describe '`date_within_range`' do
      let(:date) { today + rand(0..7).days }
      let(:max_date) { date + rand(1..30).days }
      let(:request) { double('request') }
      subject { described_class.new(member_id, request) }
      let(:call_method) { subject.send(:date_within_range, date, max_date) }
      it 'creates a new CalendarService instance with the request' do
        expect(CalendarService).to receive(:new).with(request).and_return(calendar_service)
        call_method
      end
      it 'calls `holidays` on the CalendarService instance with today as the min_date arg' do
        expect(calendar_service).to receive(:holidays).with(today, anything).and_return([])
        call_method
      end
      it 'calls `holidays` on the CalendarService instance with the max_date arg' do
        expect(calendar_service).to receive(:holidays).with(anything, max_date).and_return([])
        call_method
      end
      it 'returns false if the passed date is a Sunday' do
        date = instance_double(Date, sunday?: true, :+ => nil)
        expect(subject.send(:date_within_range, date, max_date)).to be false
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

    describe '`sequence_name`' do
      it 'returns "LC_" and the current year' do
        expect(subject.send(:sequence_name)).to eq("LC_#{today.year}")
      end
    end

    describe '`next_in_sequence`' do
      let(:sequence_name) { SecureRandom.hex }
      let(:sequence) { double('sequence', to_i: nil) }
      let(:cursor) { double('cursor', fetch: [sequence]) }
      let(:call_method) { subject.send(:next_in_sequence) }
      before do
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(cursor)
        allow(subject).to receive(:sequence_name).and_return(sequence_name)
        allow(ActiveRecord::Base.connection).to receive(:quote_table_name).and_return(sequence_name)
      end

      it 'fetches the `sequence_name`' do
        expect(subject).to receive(:sequence_name)
        call_method
      end
      it 'calls `quote_table_name` with the `sequence_name`' do
        expect(ActiveRecord::Base.connection).to receive(:quote_table_name).with(sequence_name)
        call_method
      end
      it 'calls execute on the ActiveRecord::Base.connection with the proper SQL' do
        sql = "SELECT #{sequence_name}.nextval FROM dual"
        expect(ActiveRecord::Base.connection).to receive(:execute).with(sql).and_return(cursor)
        call_method
      end
      it 'calls `fetch` on the returned cursor' do
        expect(cursor).to receive(:fetch).and_return([sequence])
        call_method
      end
      it 'calls `to_i` on the first fetched value' do
        expect(sequence).to receive(:to_i)
        call_method
      end
      it 'returns the integer value of the first fetched value' do
        allow(sequence).to receive(:to_i).and_return(sequence)
        expect(call_method).to eq(sequence)
      end
    end

    describe '`create_sequence`' do
      let(:sequence_name) { SecureRandom.hex }
      let(:call_method) { subject.send(:create_sequence) }
      before do
        allow(subject).to receive(:sequence_name).and_return(sequence_name)
        allow(ActiveRecord::Base.connection).to receive(:execute)
        allow(ActiveRecord::Base.connection).to receive(:quote_table_name).and_return(sequence_name)
      end
      describe 'the SQL statement' do
        let(:ensure_order_regexp) { '(?:\A\s*CREATE\s+SEQUENCE\s+\w+\s+)(?:.*)' }
        it 'fetches the `sequence_name`' do
          expect(subject).to receive(:sequence_name)
          call_method
        end
        it 'calls `quote_table_name` with the `sequence_name`' do
          expect(ActiveRecord::Base.connection).to receive(:quote_table_name).with(sequence_name)
          call_method
        end
        it 'creates a sequence with the sequence name' do
          matcher = Regexp.new(/\A\s*CREATE\s+SEQUENCE\s+#{sequence_name}\s+/i)
          expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher)
          call_method
        end
        it 'starts incrementing the sequence at 500' do
          matcher = Regexp.new(/#{ensure_order_regexp}START\s+WITH\s+500\s*/im)
          expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher)
          call_method
        end
        it 'increments by 1' do
          matcher = Regexp.new(/#{ensure_order_regexp}INCREMENT\s+BY\s+1\s*/im)
          expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher)
          call_method
        end
        it 'does not cache' do
          matcher = Regexp.new(/#{ensure_order_regexp}NOCACHE\s+/im)
          expect(ActiveRecord::Base.connection).to receive(:execute).with(matcher)
          call_method
        end
      end
      it 'executes the SQL' do
        expect(ActiveRecord::Base.connection).to receive(:execute)
        call_method
      end
      it 'returns the result of the execution' do
        result = double('some SQL result')
        allow(ActiveRecord::Base.connection).to receive(:execute).and_return(result)
        expect(call_method).to eq(result)
      end
    end

    describe '`set_lc_number`' do
      let(:lc_number) { double('lc number') }
      let(:sequence) { SecureRandom.hex }
      let(:call_method) { subject.send(:set_lc_number) }

      shared_examples 'an `lc_number` setter' do
        it 'sets `lc_number` to a string including the year and the result of `next_in_sequence`' do
          call_method
          expect(subject.lc_number).to eq("#{Time.zone.today.year}-#{sequence}")
        end
        it 'returns the `lc_number`' do
          expect(call_method).to eq("#{Time.zone.today.year}-#{sequence}")
        end
      end

      context 'when the `lc_number` attribute already exists' do
        before { subject.instance_variable_set(:@lc_number, lc_number) }

        it 'returns the lc_number' do
          expect(call_method).to eq(lc_number)
        end
      end
      context 'when the `lc_number` attribute does not yet exist' do
        it 'calls `next_in_sequence`' do
          expect(subject).to receive(:next_in_sequence)
          call_method
        end
        context 'when `next_in_sequence` does not raise an error' do
          before { allow(subject).to receive(:next_in_sequence).and_return(sequence) }
          it_behaves_like 'an `lc_number` setter'
        end
        context 'when `next_in_sequence` raises an ActiveRecord::StatementInvalid error' do
          before { allow(subject).to receive(:next_in_sequence).and_raise(ActiveRecord::StatementInvalid, 'message') }

          it 'calls `next_in_new_sequence`' do
            expect(subject).to receive(:next_in_new_sequence)
            call_method
          end
          context 'when `next_in_new_sequence` does not raise an error' do
            before { allow(subject).to receive(:next_in_new_sequence).and_return(sequence) }
            it_behaves_like 'an `lc_number` setter'
          end
          it 'raises an error if `next_in_new_sequence` raises an error' do
            error = ActiveRecord::StatementInvalid.new('message')
            allow(subject).to receive(:next_in_new_sequence).and_raise(error)
            expect{call_method}.to raise_error(error)
          end
        end
      end
    end

    describe '`next_in_new_sequence`' do
      let(:sequence) { SecureRandom.hex }
      let(:error) { ActiveRecord::StatementInvalid.new('message') }
      let(:call_method) { subject.send(:next_in_new_sequence) }
      before { allow(subject).to receive(:next_in_sequence) }

      it 'calls `create_sequence`' do
        expect(subject).to receive(:create_sequence)
        call_method
      end
      it 'catches `ActiveRecord::StatementInvalid` errors raised by `create_sequence`' do
        allow(subject).to receive(:create_sequence).and_raise(error)
        expect{call_method}.not_to raise_error
      end
      it 'calls `next_in_sequence`' do
        expect(subject).to receive(:next_in_sequence)
        call_method
      end
      it 'returns the result of `next_in_sequence`' do
        allow(subject).to receive(:next_in_sequence).and_return(sequence)
        expect(call_method).to eq(sequence)
      end
      it 'raises an error if `next_in_sequence` raises an error' do
        allow(subject).to receive(:next_in_sequence).and_raise(error)
        expect{call_method}.to raise_error(error)
      end
    end

    describe '`fetch_member_profile`' do
      let(:member_profile) { double('member_profile')}
      let(:member_balance_service) { instance_double(MemberBalanceService, profile: member_profile) }
      let(:call_method) { subject.send(:fetch_member_profile) }
      before { allow(MemberBalanceService).to receive(:new).and_return(member_balance_service) }

      it 'creates a new instance of MemberBalanceService with the member_id and request' do
        expect(MemberBalanceService).to receive(:new).with(subject.member_id, subject.request).and_return(member_balance_service)
        call_method
      end
      it 'calls `profile` on the `member_balance_service`' do
        expect(member_balance_service).to receive(:profile).and_return(member_profile)
        call_method
      end
      it 'returns the same object on each call' do
        profile = call_method
        expect(call_method).to be(profile)
      end
    end

    describe '`past_issue_date_restriction_window?`' do
      let(:time_limit) { Time.zone.parse(described_class::ISSUE_DATE_TIME_RESTRICTION) + described_class::ISSUE_DATE_TIME_RESTRICTION_WINDOW }
      let(:call_method) { subject.send(:past_issue_date_restriction_window?) }
      it 'returns false if the current time is before the ISSUE_DATE_TIME_RESTRICTION plus the ISSUE_DATE_TIME_RESTRICTION_WINDOW' do
        allow(Time.zone).to receive(:now).and_return(time_limit - 1.minute)
        expect(call_method).to be false
      end
      it 'returns false if the current time is exactly the ISSUE_DATE_TIME_RESTRICTION plus the ISSUE_DATE_TIME_RESTRICTION_WINDOW' do
        allow(Time.zone).to receive(:now).and_return(time_limit)
        expect(call_method).to be false
      end
      it 'returns true if the current time is after the ISSUE_DATE_TIME_RESTRICTION plus the ISSUE_DATE_TIME_RESTRICTION_WINDOW' do
        allow(Time.zone).to receive(:now).and_return(time_limit + 1.minute)
        expect(call_method).to be true
      end
    end
  end
end