require 'rails_helper'
include ReportsHelper
include CustomFormattingHelper

RSpec.describe LettersOfCreditController, :type => :controller do
  login_user

  let(:member_id) { double('A Member ID') }
  before do
    allow(controller).to receive(:current_member_id).and_return(member_id)
  end

  shared_examples 'a LettersOfCreditController action that sets page-specific instance variables with a before filter' do
    it 'sets the active nav to `:letters_of_credit`' do
      expect(controller).to receive(:set_active_nav).with(:letters_of_credit)
      call_action
    end
    it 'sets the `@html_class` to `white-background` if no class has been set' do
      call_action
      expect(assigns[:html_class]).to eq('white-background')
    end
    it 'does not set `@html_class` if it has already been set' do
      html_class = instance_double(String)
      controller.instance_variable_set(:@html_class, html_class)
      call_action
      expect(assigns[:html_class]).to eq(html_class)
    end
  end

  shared_examples 'a LettersOfCreditController action that sets sidebar view variables with a before filter' do
    let(:contacts) { double('contacts') }
    before do
      allow(controller).to receive(:member_contacts).and_return(contacts)
    end

    it 'calls `sanitized_profile`' do
      expect(controller).to receive(:sanitized_profile)
      call_action
    end
    it 'sets `@profile` to the result of calling `sanitized_profile`' do
      profile = double('member profile')
      allow(controller).to receive(:sanitized_profile).and_return(profile)
      call_action
      expect(assigns[:profile]).to eq(profile)
    end
    it 'calls `member_contacts`' do
      expect(controller).to receive(:member_contacts).and_return(contacts)
      call_action
    end
    it 'sets `@contacts` to the result of `member_contacts`' do
      call_action
      expect(assigns[:contacts]).to eq(contacts)
    end
  end

  describe 'GET manage' do
    let(:historic_locs) { instance_double(Array) }
    let(:member_balance_service) { instance_double(MemberBalanceService, letters_of_credit: {credits: []}, todays_credit_activity: []) }
    let(:lc) { {instrument_type: described_class::LC_INSTRUMENT_TYPE} }
    let(:call_action) { get :manage }

    before do
      allow(MemberBalanceService).to receive(:new).and_return(member_balance_service)
      allow(controller).to receive(:dedupe_locs)
    end

    it_behaves_like 'a user required action', :get, :manage
    it_behaves_like 'a LettersOfCreditController action that sets page-specific instance variables with a before filter'
    it 'calls `set_titles` with its title' do
      expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.manage.title'))
      call_action
    end
    it 'creates a new instance of MemberBalanceService' do
      expect(MemberBalanceService).to receive(:new).with(member_id, request).and_return(member_balance_service)
      call_action
    end
    [:letters_of_credit, :todays_credit_activity].each do |service_method|
      it "raises an error if the `MemberBalanceService##{service_method}` returns nil" do
        allow(member_balance_service).to receive(service_method).and_return(nil)
        expect{call_action}.to raise_error(StandardError, "There has been an error and LettersOfCreditController#manage has encountered nil. Check error logs.")
      end
    end
    it 'calls `dedupe_locs` with the `credits` array from the `letters_of_credit` endpoint' do
      allow(member_balance_service).to receive(:letters_of_credit).and_return({credits: historic_locs})
      expect(controller).to receive(:dedupe_locs).with(anything, historic_locs)
      call_action
    end
    it "calls `dedupe_locs` with activities from the `todays_credit_activity` that have an `instrument_type` of `#{described_class::LC_INSTRUMENT_TYPE}`" do
      advance = {instrument_type: 'ADVANCE'}
      investment = {instrument_type: 'INVESTMENT'}
      intraday_activities = [advance, investment, lc]
      allow(member_balance_service).to receive(:todays_credit_activity).and_return(intraday_activities)
      expect(controller).to receive(:dedupe_locs).with([lc], anything)
      call_action
    end
    it 'calls `dedupe_locs` with the intraday and historic locs' do
      intraday_locs = [lc]
      allow(member_balance_service).to receive(:todays_credit_activity).and_return(intraday_locs)
      allow(member_balance_service).to receive(:letters_of_credit).and_return({credits: historic_locs})
      expect(controller).to receive(:dedupe_locs).with(intraday_locs, historic_locs)
      call_action
    end
    it 'sorts the deduped locs by `lc_number`' do
      lc_array = instance_double(Array)
      allow(controller).to receive(:dedupe_locs).and_return(lc_array)
      expect(controller).to receive(:sort_report_data).with(lc_array, :lc_number).and_return([{}])
      call_action
    end
    describe '`@table_data`' do
      it 'has the proper `column_headings`' do
        column_headings = [I18n.t('reports.pages.letters_of_credit.headers.lc_number'), fhlb_add_unit_to_table_header(I18n.t('reports.pages.letters_of_credit.headers.current_amount'), '$'), I18n.t('global.issue_date'), I18n.t('letters_of_credit.manage.expiration_date'), I18n.t('reports.pages.letters_of_credit.headers.credit_program'), I18n.t('reports.pages.letters_of_credit.headers.annual_maintenance_charge'), I18n.t('global.actions')]
        call_action
        expect(assigns[:table_data][:column_headings]).to eq(column_headings)
      end
      describe 'table `rows`' do
        it 'is an empty array if there are no letters of credit' do
          allow(controller).to receive(:dedupe_locs).and_return([])
          call_action
          expect(assigns[:table_data][:rows]).to eq([])
        end
        it 'builds a row for each letter of credit returned by `dedupe_locs`' do
          n = rand(1..10)
          credits = []
          n.times { credits << {lc_number: SecureRandom.hex} }
          allow(controller).to receive(:dedupe_locs).and_return(credits)
          call_action
          expect(assigns[:table_data][:rows].length).to eq(n)
        end
        loc_value_types = [[:lc_number, nil], [:current_par, :currency_whole], [:trade_date, :date], [:maturity_date, :date], [:description, nil], [:maintenance_charge, :basis_point]]
        loc_value_types.each_with_index do |attr, i|
          attr_name = attr.first
          attr_type = attr.last
          describe "columns with cells based on the LC attribute `#{attr_name}`" do
            let(:credit) { {attr_name => double(attr_name.to_s)} }
            before { allow(controller).to receive(:dedupe_locs).and_return([credit]) }

            it "builds a cell with a `value` of `#{attr_name}`" do
              call_action
              expect(assigns[:table_data][:rows].length).to be > 0
              assigns[:table_data][:rows].each do |row|
                expect(row[:columns][i][:value]).to eq(credit[attr_name])
              end
            end
            it "builds a cell with a `type` of `#{attr_type}`" do
              call_action
              expect(assigns[:table_data][:rows].length).to be > 0
              assigns[:table_data][:rows].each do |row|
                expect(row[:columns][i][:type]).to eq(attr_type)
              end
            end
          end
        end
        describe 'columns with cells referencing possible actions for a given LC' do
          before { allow(controller).to receive(:dedupe_locs).and_return([{}]) }

          it "builds a cell with a `value` of `#{I18n.t('global.view_pdf')}`" do
            call_action
            expect(assigns[:table_data][:rows].length).to be > 0
            assigns[:table_data][:rows].each do |row|
              expect(row[:columns].last[:value]).to eq(I18n.t('global.view_pdf'))
            end
          end
          it 'builds a cell with a nil `type`' do
            call_action
            expect(assigns[:table_data][:rows].length).to be > 0
            assigns[:table_data][:rows].each do |row|
              expect(row[:columns].last[:type]).to be nil
            end
          end
        end
      end
    end
  end

  describe 'GET new' do
    let(:call_action) { get :new }
    before do
      allow(controller).to receive(:populate_new_request_view_variables)
      allow(controller).to receive(:sanitized_profile)
      allow(controller).to receive(:member_contacts)
    end

    allow_policy :letters_of_credit, :request?

    it_behaves_like 'a user required action', :get, :new
    it_behaves_like 'a LettersOfCreditController action that sets page-specific instance variables with a before filter'
    it_behaves_like 'a LettersOfCreditController action that sets sidebar view variables with a before filter'
    it 'calls `populate_new_request_view_variables`' do
      expect(controller).to receive(:populate_new_request_view_variables)
      call_action
    end
  end

  describe 'POST preview' do
    let(:loc_params) { {sentinel: SecureRandom.hex} }
    let(:loc) { instance_double(LetterOfCredit, valid?: true) }
    let(:call_action) { post :preview, letter_of_credit: loc_params }

    before do
      allow(LetterOfCredit).to receive(:from_hash).and_return(loc)
      allow(controller).to receive(:session_elevated?)
      allow(controller).to receive(:sanitized_profile)
      allow(controller).to receive(:member_contacts)
    end

    it 'calls `set_titles` with the appropriate title' do
      expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.request.title'))
      call_action
    end
    it 'calls `LettersOfCredit#from_hash` with the `letter_of_credit` params hash' do
      expect(LetterOfCredit).to receive(:from_hash).with(loc_params)
      call_action
    end
    it 'sets `@letter_of_credit` to the result of `LettersOfCredit#from_hash`' do
      allow(LetterOfCredit).to receive(:from_hash).and_return(loc)
      call_action
      expect(assigns[:letter_of_credit]).to eq(loc)
    end
    it 'checks to see if the session is elevated' do
      expect(controller).to receive(:session_elevated?)
      call_action
    end
    it 'sets `@session_elevated` to the result of calling `session_elevated?`' do
      elevated = double('session elevated status')
      allow(controller).to receive(:session_elevated?).and_return(elevated)
      call_action
      expect(assigns[:session_elevated]).to eq(elevated)
    end
    describe 'when the created LetterOfCredit instance is valid' do
      it 'renders the `preview` view' do
        call_action
        expect(response.body).to render_template(:preview)
      end
    end
    describe 'when the created LetterOfCredit instance is invalid' do
      let(:error_message) { instance_double(String) }
      let(:errors) {[
        [SecureRandom.hex, error_message],
        [SecureRandom.hex, instance_double(String)]
      ]}
      before do
        allow(loc).to receive(:valid?).and_return(false)
        allow(loc).to receive(:errors).and_return(errors)
        allow(controller).to receive(:populate_new_request_view_variables)
      end

      it 'sets `@error_message` to the error message of the first error in the returned error array' do
        call_action
        expect(assigns[:error_message]).to eq(error_message)
      end
      it 'calls `populate_new_request_view_variables`' do
        expect(controller).to receive(:populate_new_request_view_variables)
        call_action
      end
      it 'renders the `new` view' do
        call_action
        expect(response.body).to render_template(:new)
      end
    end
  end

  describe 'private methods' do
    describe '`dedupe_locs`' do
      let(:lc_number) { SecureRandom.hex }
      let(:intraday) { {lc_number: lc_number} }
      let(:unique_historic) { {lc_number: lc_number + SecureRandom.hex} }
      let(:duplicate_historic) { {lc_number: lc_number} }
      it 'combines unique intraday_locs and historic_locs' do
        expect(controller.send(:dedupe_locs, [intraday], [unique_historic])).to eq([intraday, unique_historic])
      end
      describe 'when intraday_locs and historic_locs have an loc with a duplicate `lc_number`' do
        let(:intraday_description) { instance_double(String) }
        let(:historic_description) { instance_double(String) }
        let(:shared_intraday_value) { double('a shared attribute') }
        let(:shared_historic_value) { double('a shared attribute') }
        let(:results) { controller.send(:dedupe_locs, [intraday], [duplicate_historic ]) }
        let(:deduped_lc) { results.select{|loc| loc[:lc_number] == lc_number}.first }
        it 'only returns one loc with that lc_number' do
          expect(results.select{|loc| loc[:lc_number] == lc_number}.length).to be 1
        end
        it 'replaces all overlapping keys with values from the intraday loc' do
          intraday[:shared_attr] = shared_intraday_value
          duplicate_historic[:shared_attr] = shared_historic_value
          expect(deduped_lc[:shared_attr]).to eq(shared_intraday_value)
        end
        it 'drops historic loc fields that are not shared by the intraday loc' do
          duplicate_historic[:unique_attr] = double('some value')
          expect(deduped_lc.keys).not_to include(:unique_attr)
        end
        it 'uses the `description` value from the intraday loc if it is available' do
          intraday[:description] = intraday_description
          duplicate_historic[:description] = historic_description
          expect(deduped_lc[:description]).to eq(intraday_description)
        end
        it 'uses the `description` value from the historic loc if there is no intraday loc description value' do
          duplicate_historic[:description] = historic_description
          expect(deduped_lc[:description]).to eq(historic_description)
        end
      end
    end

    describe '`set_titles`' do
      let(:title) { SecureRandom.hex }
      let(:call_method) { controller.send(:set_titles, title) }
      it 'sets `@title` to the given title' do
        call_method
        expect(assigns[:title]).to eq(title)
      end
      it 'sets `@page_title` by appropriately interpolating the given title' do
        call_method
        expect(assigns[:page_title]).to eq(I18n.t('global.page_meta_title', title: title))
      end
    end

    describe '`date_restrictions`' do
      let(:today) { Time.zone.today }
      let(:max_date) { today + LetterOfCredit::EXPIRATION_MAX_DATE_RESTRICTION }
      let(:weekends_and_holidays) { instance_double(Array) }
      let(:calendar_service) { instance_double(CalendarService, find_next_business_day: nil) }
      let(:call_method) { subject.send(:date_restrictions) }

      before do
        allow(CalendarService).to receive(:new).and_return(calendar_service)
        allow(controller).to receive(:weekends_and_holidays)
      end

      it 'creates a new instance of the CalendarService with the request as an arg' do
        expect(CalendarService).to receive(:new).with(request).and_return(calendar_service)
        call_method
      end
      it 'calls `find_next_business_day` on the service instance with today and a 1.day step' do
        expect(calendar_service).to receive(:find_next_business_day).with(today, 1.day)
        call_method
      end
      describe 'the returned hash' do
        it 'has a `min_date` that is the result of calling `find_next_business_day` on the calendar service instance' do
          min_date = instance_double(Date)
          allow(calendar_service).to receive(:find_next_business_day).and_return(min_date)
          call_method
          expect(call_method[:min_date]).to eq(min_date)
        end
        it 'has an `expiration_max_date` of today plus the `LetterOfCredit::EXPIRATION_MAX_DATE_RESTRICTION`' do
          expect(call_method[:expiration_max_date]).to eq(max_date)
        end
        it 'has an `issue_max_date` of today plus the `LetterOfCredit::ISSUE_MAX_DATE_RESTRICTION`' do
          expect(call_method[:issue_max_date]).to eq(today + LetterOfCredit::ISSUE_MAX_DATE_RESTRICTION)
        end
        describe 'the `invalid_dates` array' do
          it 'calls `weekends_and_holidays` with today as the start_date arg' do
            expect(controller).to receive(:weekends_and_holidays).with(start_date: today, end_date: anything, calendar_service: anything)
            call_method
          end
          it "calls `weekends_and_holidays` with a date #{LetterOfCredit::EXPIRATION_MAX_DATE_RESTRICTION} from today as the end_date arg" do
            expect(controller).to receive(:weekends_and_holidays).with(start_date: anything, end_date: (today + LetterOfCredit::EXPIRATION_MAX_DATE_RESTRICTION), calendar_service: anything)
            call_method
          end
          it 'calls `weekends_and_holidays` with the calendar service instance as the calendar_service arg' do
            expect(controller).to receive(:weekends_and_holidays).with(start_date: anything, end_date: anything, calendar_service: calendar_service)
            call_method
          end
          it 'has a value equal to the result of calling `weekends_and_holidays`' do
            allow(controller).to receive(:weekends_and_holidays).and_return(weekends_and_holidays)
            expect(call_method[:invalid_dates]).to eq(weekends_and_holidays)
          end
        end
      end
    end

    describe '`populate_new_request_view_variables`' do
      let(:call_method) { controller.send(:populate_new_request_view_variables) }
      let(:new_loc) { instance_double(LetterOfCredit) }

      before do
        allow(controller).to receive(:date_restrictions)
        allow(LetterOfCredit).to receive(:new).and_return(new_loc)
      end

      it 'calls `set_titles` with its title' do
        expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.request.title'))
        call_method
      end
      describe '`@letter_of_credit`' do
        describe 'when the instance variable already exists' do
          before { controller.instance_variable_set(:@letter_of_credit, new_loc) }
          it 'does not create a new instance of LetterOfCredit' do
            expect(LetterOfCredit).not_to receive(:new)
            call_method
          end
          it 'keeps the `@letter_of_credit` defined as-is' do
            call_method
            expect(assigns[:letter_of_credit]).to eq(new_loc)
          end
        end
        describe 'when the instance variable does not yet exist' do
          it 'creates a new instance of LetterOfCredit with the request' do
            expect(LetterOfCredit).to receive(:new).with(request)
            call_method
          end
          it 'sets `@letter_of_credit` to the result of LetterOfCredit#new' do
            allow(LetterOfCredit).to receive(:new).and_return(new_loc)
            call_method
            expect(assigns[:letter_of_credit]).to eq(new_loc)
          end
        end
      end
      describe '`@beneficiary_dropdown_options`' do
        let(:beneficiaries) {[
          {name: SecureRandom.hex},
          {name: SecureRandom.hex},
          {name: SecureRandom.hex}
        ]}
        let(:beneficiary_service) { instance_double(BeneficiariesService, all: []) }
        before { allow(BeneficiariesService).to receive(:new).and_return(beneficiary_service) }
        it 'creates a new instance of `BeneficiariesService` with the request' do
          expect(BeneficiariesService).to receive(:new).with(request).and_return(beneficiary_service)
          call_method
        end
        it 'fetches `all` of the beneficiaries from the service' do
          expect(beneficiary_service).to receive(:all).and_return([])
          call_method
        end
        it 'is an array containing arrays of beneficiary names' do
          matching_array = beneficiaries.collect{|x| [x[:name], x[:name]]}
          allow(beneficiary_service).to receive(:all).and_return(beneficiaries)
          call_method
          expect(assigns[:beneficiary_dropdown_options]).to eq(matching_array)
        end
      end
      describe '`@date_restrictions`' do
        it 'calls `date_restrictions`' do
          expect(controller).to receive(:date_restrictions)
          call_method
        end
        it 'sets `@date_restrictions` to the result of the `date_restrictions` method' do
          date_restrictions = double('date restrictions')
          allow(controller).to receive(:date_restrictions).and_return(date_restrictions)
          call_method
          expect(assigns[:date_restrictions]).to eq(date_restrictions)
        end
      end
    end
  end
end