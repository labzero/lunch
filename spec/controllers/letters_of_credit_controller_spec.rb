require 'rails_helper'
include ReportsHelper
include CustomFormattingHelper

RSpec.describe LettersOfCreditController, :type => :controller do
  login_user

  let(:member_id) { double('A Member ID') }
  let(:member) {{
    name: double('name'),
    fhfa_number: double('fhfa number'),
    customer_lc_agreement_flag: double('customer lc agreement flag')
  }}
  let(:letter_of_credit_request) { instance_double(LetterOfCreditRequest, save: nil, :attributes= => nil, beneficiary_name: nil, owners: instance_double(Set, add: nil), lc_number: nil, id: nil) }
  let(:beneficiary_request) { instance_double(BeneficiaryRequest, save: nil, :attributes= => nil, owners: instance_double(Set, add: nil), id: nil) }
  let(:members_service) { double("A Member Service") }

  before do
    allow(controller).to receive(:current_member_id).and_return(member_id)
    allow(MembersService).to receive(:new).and_return(members_service)
    allow(members_service).to receive(:member).with(member_id).and_return(member)
    allow(controller).to receive(:sanitized_profile)
    allow(controller).to receive(:member_contacts)
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

  shared_examples 'a LettersOfCreditController action that fetches a letter of credit request' do
    it 'fetches the letter of credit request' do
      expect(controller).to receive(:fetch_letter_of_credit_request) do
        controller.instance_variable_set(:@letter_of_credit_request, letter_of_credit_request)
      end
      call_action
    end
  end

  shared_examples 'a LettersOfCreditController action that saves a letter of credit request' do
    it 'saves the letter of credit request' do
      expect(controller).to receive(:save_letter_of_credit_request)
      call_action
    end
  end

  shared_examples 'a LettersOfCreditController action that sets the customer LC agreement flag' do
    it 'creates a new instance of MembersService with the request' do
      expect(MembersService).to receive(:new).with(request).and_return(members_service)
      call_action
    end
    it 'calls `member` on the instance of MembersService with the current_member_id' do
      allow(controller).to receive(:current_member_id).and_return(member_id)
      expect(members_service).to receive(:member).with(member_id).and_return(member)
      call_action
    end
    it 'raises an error if no member is found' do
      allow(members_service).to receive(:member).with(member_id).and_return(nil)
      expect{call_action}.to raise_error(ActionController::RoutingError)
    end
    it 'sets the `@customer_lc_agreement_flag` to the customer_lc_agreement_flag value of the member hash' do
      call_action
      expect(assigns[:lc_agreement_flag]).to eq(member[:customer_lc_agreement_flag])
    end
  end

  shared_examples 'a LettersOfCreditController action that creates a downloadable PDF of the request' do |view, file_name|
    let(:members_service) { instance_double(MembersService, member: member) }
    let(:id) { SecureRandom.hex }
    let(:call_action) { get view.to_sym, letter_of_credit_request: {id: id} }
    before do
      allow(LetterOfCreditRequest).to receive(:find).and_return(letter_of_credit_request)
      allow(MembersService).to receive(:new).and_return(members_service)
      allow(subject).to receive(:authorize).with(letter_of_credit_request, :modify?)
    end

    allow_policy :letters_of_credit, :request?
    allow_policy :letters_of_credit, :modify?

    it_behaves_like 'a user required action', :get, :view
    it_behaves_like 'a LettersOfCreditController action that sets page-specific instance variables with a before filter'

    it 'finds the LetterOfCreditRequest based on the id param and the request' do
      expect(LetterOfCreditRequest).to receive(:find).with(id, request).and_return(letter_of_credit_request)
      call_action
    end
    it 'sets the `@letter_of_credit_request` instance variable to the result `LetterOfCreditRequest.find`' do
      call_action
      expect(assigns[:letter_of_credit_request]).to eq(letter_of_credit_request)
    end

    it 'sets the `@is_amendment` instance variable to `true` if amending an existing LoC' do
      call_action
      expect(assigns[:is_amendment]).to eq(true) if view.to_s.eql?('amend_view')
    end

    describe 'when there is an `export_format` param that is `pdf`' do
      let(:job_status) { double('job_status', :update_attributes! => nil) }
      let(:performed_job) { double('performed job', job_status: job_status) }
      let(:call_action) { get view.to_sym, {letter_of_credit_request: {id: id}, export_format: 'pdf'} }

      before do
        allow(RenderLetterOfCreditPDFJob).to receive(:perform_later).and_return(performed_job)
      end

      it 'calls `perform_later` on the `RenderLetterOfCreditPDFJob` with the current_member_id' do
        expect(RenderLetterOfCreditPDFJob).to receive(:perform_later).with(member_id, any_args).and_return(performed_job)
        call_action
      end
      it 'calls `perform_later` on the `RenderLetterOfCreditPDFJob` with the current action name' do
        expect(RenderLetterOfCreditPDFJob).to receive(:perform_later).with(anything, view.to_s, any_args).and_return(performed_job)
        call_action
      end
      it 'calls `perform_later` on the `RenderLetterOfCreditPDFJob` with a pdf name that includes the lc_number of the letter of credit request' do
        lc_number = SecureRandom.hex
        allow(letter_of_credit_request).to receive(:lc_number).and_return(lc_number)
        file_name = view.to_s.eql?('amend_view') ? "letter_of_credit_request_amendment_#{lc_number}.pdf" : "letter_of_credit_request_confirmation_#{lc_number}.pdf"
        expect(RenderLetterOfCreditPDFJob).to receive(:perform_later).with(anything, anything, file_name, any_args).and_return(performed_job)
        call_action
      end
      it 'calls `perform_later` on the `RenderLetterOfCreditPDFJob` with the letter_of_credit_request id' do
        allow(letter_of_credit_request).to receive(:id).and_return(id)
        expect(RenderLetterOfCreditPDFJob).to receive(:perform_later).with(anything, anything, anything, {letter_of_credit_request: {id: id}}).and_return(performed_job)
        call_action
      end
      it 'calls `job_status` on the result of `perform_later`' do
        expect(performed_job).to receive(:job_status).and_return(job_status)
        call_action
      end
      it 'updates the `job_status` with the current user id' do
        user = instance_double(User, id: SecureRandom.hex, accepted_terms?: true)
        allow(controller).to receive(:current_user).and_return(user)
        expect(job_status).to receive(:update_attributes!).with(user_id: user.id)
        call_action
      end
      it 'renders JSON with a `job_status_url`' do
        call_action
        expect(JSON.parse(response.body)['job_status_url']).to eq(job_status_url(job_status))
      end
      it 'renders JSON with a `job_cancel_url`' do
        call_action
        expect(JSON.parse(response.body)['job_cancel_url']).to eq(job_cancel_url(job_status))
      end
    end
    describe 'when there is no `export_format` param' do
      it 'creates a new instance of MembersService with the request' do
        expect(MembersService).to receive(:new).with(request).and_return(members_service)
        call_action
      end
      it 'calls `member` on the instance of MembersService with the current_member_id' do
        expect(members_service).to receive(:member).with(member_id).and_return(member)
        call_action
      end
      it 'raises an error if no member is found' do
        allow(members_service).to receive(:member)
        expect{call_action}.to raise_error(ActionController::RoutingError)
      end
      it 'sets `@member_name` to the name value of the member hash' do
        call_action
        expect(assigns[:member_name]).to eq(member[:name])
      end
      it 'sets `@member_fhla` to the fhfa_number value of the member hash' do
        call_action
        expect(assigns[:member_fhfa]).to eq(member[:fhfa_number])
      end
      it 'renders its view' do
        call_action
        expect(response.body).to render_template(view.to_sym)
      end
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
    it_behaves_like 'a LettersOfCreditController action that sets the customer LC agreement flag'

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
        column_headings = [I18n.t('reports.pages.letters_of_credit.headers.lc_number'), I18n.t('reports.pages.letters_of_credit.headers.beneficiary'), fhlb_add_unit_to_table_header(I18n.t('reports.pages.letters_of_credit.headers.current_amount'), '$'), I18n.t('global.issue_date'), I18n.t('letters_of_credit.manage.expiration_date'), I18n.t('reports.pages.letters_of_credit.headers.credit_program'), I18n.t('reports.pages.letters_of_credit.headers.annual_maintenance_charge'), I18n.t('global.actions')]
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
        describe "populated rows" do
          let(:credit) { {lc_number: double('lc_number'), beneficiary: double('beneficiary'), current_par: double('current_par'), trade_date: double('trade_date'), maturity_date: double('maturity_date'), description: double('description'), maintenance_charge: double('maintenance_charge') } }
          before {
            allow(controller).to receive(:dedupe_locs).and_return([credit])
            allow(credit[:beneficiary]).to receive(:truncate).and_return(credit[:beneficiary])
            allow(credit[:beneficiary]).to receive(:gsub).with(/\,..$/, '..').and_return(credit[:beneficiary])
          }

          loc_value_types = [[:lc_number, nil], [:beneficiary, nil], [:current_par, :currency_whole], [:trade_date, :date], [:maturity_date, :date], [:description, nil], [:maintenance_charge, :basis_point]]
          loc_value_types.each_with_index do |attr, i|
            attr_name = attr.first
            attr_type = attr.last
            describe "columns with cells based on the LC attribute `#{attr_name}`" do
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
        end
        describe 'columns with cells referencing possible actions for a given LC' do
          before { allow(controller).to receive(:dedupe_locs).and_return([{}]) }

          it "builds a cell with a `value` of `#{I18n.t('global.view_pdf')}`" do
            call_action
            expect(assigns[:table_data][:rows].length).to be > 0
            assigns[:table_data][:rows].each do |row|
              expect(row[:columns][7][:value]).to eq(I18n.t('global.view_pdf'))
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

  describe 'GET view' do
    it_behaves_like 'a LettersOfCreditController action that creates a downloadable PDF of the request', :view
  end

  describe 'GET amend_view' do
    it_behaves_like 'a LettersOfCreditController action that creates a downloadable PDF of the request', :amend_view
  end

  context 'controller actions that fetch a beneficiary request' do
    before do
      allow(controller).to receive(:fetch_beneficiary_request) do
        controller.instance_variable_set(:@beneficiary_request, beneficiary_request)
      end
    end

    describe 'GET beneficiary' do
      let(:call_action) { get :beneficiary }

      it_behaves_like 'a user required action', :get, :beneficiary

      it 'calls `set_titles` with the appropriate title' do
        expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.beneficiary.add'))
        call_action
      end

      it 'sets `@states_dropdown` to a list of states' do
        call_action
        expect(assigns[:states_dropdown]).to eq(described_class::STATES.collect{|state| [state[0].to_s + ' - ' + state[1].to_s, state[0]]}.unshift(I18n.t('letters_of_credit.beneficiary.select_state')))
      end

      it 'sets `@states_dropdown_default` to `Select State`' do
        call_action
        expect(assigns[:states_dropdown_default]).to eq(I18n.t('letters_of_credit.beneficiary.select_state'))
      end
    end

    describe 'POST beneficiary_new' do
      let(:loc_params) { {sentinel: SecureRandom.hex} }
      let(:call_action) { post :beneficiary_new, beneficiary_request: loc_params }
      let(:beneficiary_json) { double('loc as json') }
      let(:mailer) { double('mailer', deliver_now: nil) }
      let(:user) { instance_double(User, display_name: nil, accepted_terms?: true, id: nil, email: nil) }

      before do
        allow(beneficiary_request).to receive(:valid?).and_return(true)
        allow(MemberMailer).to receive(:beneficiary_request).and_return(mailer)
      end

      allow_policy :letters_of_credit, :request?

      it_behaves_like 'a user required action', :post, :beneficiary_new, beneficiary_request: {}
      it 'calls `set_titles` with the appropriate title' do
        expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.beneficiary_new.title'))
        call_action
      end
      it 'sets the attributes of the letter of credit request with the `letter_of_credit_request` params hash' do
        expect(beneficiary_request).to receive(:attributes=).with(loc_params)
        call_action
      end
      describe 'when the created LetterOfCreditRequest instance is valid' do
        it 'renders the `preview` view' do
          call_action
          expect(response.body).to render_template(:beneficiary_new)
        end
        it 'converts the beneficiary  request to JSON' do
          expect(beneficiary_request).to receive(:to_json)
          call_action
        end
        it 'calls `InternalMailer#beneficiary_request` with the request' do
          expect(MemberMailer).to receive(:beneficiary_request).with(request, any_args).and_return(mailer)
          call_action
        end
        it 'calls `InternalMailer#beneficiary_request` with the current_member_id' do
          expect(MemberMailer).to receive(:beneficiary_request).with(anything, member_id, any_args).and_return(mailer)
          call_action
        end
        it 'calls `InternalMailer#beneficiary_request` with the beneficiary as JSON' do
          allow(beneficiary_request).to receive(:to_json).and_return(beneficiary_json)
          expect(MemberMailer).to receive(:beneficiary_request).with(anything, anything, beneficiary_json, any_args).and_return(mailer)
          call_action
        end
        it 'calls `InternalMailer#beneficiary_request` with the current_user' do
          allow(controller).to receive(:current_user).and_return(user)
          expect(MemberMailer).to receive(:beneficiary_request).with(anything, anything, anything, user).and_return(mailer)
          call_action
        end
        it 'calls `deliver_now` on the result of `InternalMailer#beneficiary_request`' do
          expect(mailer).to receive(:deliver_now)
          call_action
        end
      end
    end
  end

  context 'controller actions that fetch a letter of credit request' do

    before do
      allow(controller).to receive(:fetch_letter_of_credit_request) do
        controller.instance_variable_set(:@letter_of_credit_request, letter_of_credit_request)
      end
    end

    describe 'GET new' do
      let(:call_action) { get :new }
      before { allow(controller).to receive(:populate_new_request_view_variables) }

      allow_policy :letters_of_credit, :request?

      it_behaves_like 'a user required action', :get, :new
      it_behaves_like 'a LettersOfCreditController action that sets the customer LC agreement flag'
      it_behaves_like 'a LettersOfCreditController action that sets page-specific instance variables with a before filter'
      it_behaves_like 'a LettersOfCreditController action that sets sidebar view variables with a before filter'
      it_behaves_like 'a LettersOfCreditController action that fetches a letter of credit request'
      it_behaves_like 'a LettersOfCreditController action that saves a letter of credit request'
      it 'calls `populate_new_request_view_variables`' do
        expect(controller).to receive(:populate_new_request_view_variables)
        call_action
      end
    end

    describe 'POST preview' do
      let(:loc_params) { {sentinel: SecureRandom.hex} }
      let(:call_action) { post :preview, letter_of_credit_request: loc_params }

      before do
        allow(letter_of_credit_request).to receive(:valid?).and_return(true)
        allow(controller).to receive(:member_contacts)
      end

      allow_policy :letters_of_credit, :request?

      it_behaves_like 'a user required action', :post, :preview, letter_of_credit_request: {}
      it_behaves_like 'a LettersOfCreditController action that sets page-specific instance variables with a before filter'
      it_behaves_like 'a LettersOfCreditController action that sets sidebar view variables with a before filter'
      it_behaves_like 'a LettersOfCreditController action that fetches a letter of credit request'
      it_behaves_like 'a LettersOfCreditController action that saves a letter of credit request'
      it 'calls `set_titles` with the appropriate title' do
        expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.request.title'))
        call_action
      end
      it 'sets the attributes of the letter of credit request with the `letter_of_credit_request` params hash' do
        expect(letter_of_credit_request).to receive(:attributes=).with(loc_params)
        call_action
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
      describe 'when the created LetterOfCreditRequest instance is valid' do
        it 'renders the `preview` view' do
          call_action
          expect(response.body).to render_template(:preview)
        end
      end
      describe 'when the created LetterOfCreditRequest instance is invalid' do
        let(:error_message) { instance_double(String) }
        before do
          allow(letter_of_credit_request).to receive(:valid?).and_return(false)
          allow(controller).to receive(:populate_new_request_view_variables)
          allow(controller).to receive(:prioritized_error_message)
        end

        it 'calls `prioritized_error_message` with the letter of credit request' do
          expect(controller).to receive(:prioritized_error_message).with(letter_of_credit_request)
          call_action
        end
        it 'sets `@error_message` to the result of `prioritized_error_message`' do
          allow(controller).to receive(:prioritized_error_message).and_return(error_message)
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

    describe 'POST execute' do
      let(:rm) {{
        email: SecureRandom.hex,
        phone_number: SecureRandom.hex
      }}
      let(:name) { double('name') }
      let(:user) { instance_double(User, display_name: name, accepted_terms?: true, id: nil) }
      let(:securid_status) { double('some status') }
      let(:call_action) { post :execute }

      before do
        allow(controller).to receive(:member_contacts).and_return({rm: rm})
        allow(controller).to receive(:securid_perform_check).and_return(securid_status)
      end

      allow_policy :letters_of_credit, :request?

      it_behaves_like 'a user required action', :post, :amend_execute
      it_behaves_like 'a LettersOfCreditController action that sets page-specific instance variables with a before filter'
      it_behaves_like 'a LettersOfCreditController action that sets sidebar view variables with a before filter'
      it_behaves_like 'a LettersOfCreditController action that fetches a letter of credit request'
      it_behaves_like 'a LettersOfCreditController action that saves a letter of credit request'

      shared_examples 'an unsuccessful execution' do
        it 'calls `set_titles` with the Preview title' do
          expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.request.title'))
          call_action
        end
        it 'renders the `preview` view' do
          call_action
          expect(response.body).to render_template(:preview)
        end
      end

      context 'when the requester is not permitted to execute the letter of credit' do
        deny_policy :letters_of_credit, :execute?

        it_behaves_like 'an unsuccessful execution'
        it 'sets `@error_message` to the not-authorized message' do
          call_action
          expect(assigns[:error_message]).to eq(I18n.t('letters_of_credit.errors.not_authorized'))
        end
      end

      context 'when the requester is permitted to execute the letter of credit' do
        allow_policy :letters_of_credit, :execute?

        it 'performs a securid check' do
          expect(controller).to receive(:securid_perform_check)
          call_action
        end
        context 'when the session is not elevated' do
          before { allow(controller).to receive(:session_elevated?).and_return(false) }

          it_behaves_like 'an unsuccessful execution'
          it 'sets `@securid_status` to the result of `securid_perform_check`' do
            call_action
            expect(assigns[:securid_status]).to eq(securid_status)
          end
        end
        context 'when the session is elevated' do
          before { allow(controller).to receive(:session_elevated?).and_return(true) }

          shared_examples 'a letter of credit request with a generic error' do

            it_behaves_like 'an unsuccessful execution'
            it 'sets `@error_message` to the generic error message' do
              call_action
              expect(assigns[:error_message]).to eq(I18n.t('letters_of_credit.errors.generic_html', rm_email: rm[:email], rm_phone_number: rm[:phone_number]))
            end
          end

          context 'when the letter of credit request is not valid' do
            before { allow(letter_of_credit_request).to receive(:valid?).and_return(false) }
            it_behaves_like 'a letter of credit request with a generic error'
          end
          context 'when the letter of credit request is valid' do
            before { allow(letter_of_credit_request).to receive(:valid?).and_return(true) }

            it 'calls `execute` on the letter of credit request with the display_name of the current_user' do
              allow(controller).to receive(:current_user).and_return(user)
              expect(letter_of_credit_request).to receive(:execute).with(name)
              call_action
            end

            context 'when the execution of the letter of credit request fails' do
              before { allow(letter_of_credit_request).to receive(:execute).and_return(false) }
              it_behaves_like 'a letter of credit request with a generic error'
            end
            context 'when the execution of the letter of credit request succeeds' do
              let(:letter_of_credit_json) { double('loc as json') }
              let(:mailer) { double('mailer', deliver_later: nil) }
              before do
                allow(letter_of_credit_request).to receive(:execute).and_return(true)
                allow(MemberMailer).to receive(:letter_of_credit_request).and_return(mailer)
              end

              it 'converts the letter of credit request to JSON' do
                expect(letter_of_credit_request).to receive(:to_json)
                call_action
              end
              it 'calls `InternalMailer#letter_of_credit_request` with the current_member_id' do
                expect(MemberMailer).to receive(:letter_of_credit_request).with(member_id, any_args).and_return(mailer)
                call_action
              end
              it 'calls `InternalMailer#letter_of_credit_request` with the letter of credit as JSON' do
                allow(letter_of_credit_request).to receive(:to_json).and_return(letter_of_credit_json)
                expect(MemberMailer).to receive(:letter_of_credit_request).with(anything, letter_of_credit_json, any_args).and_return(mailer)
                call_action
              end
              it 'calls `InternalMailer#letter_of_credit_request` with the current_user' do
                allow(controller).to receive(:current_user).and_return(user)
                expect(MemberMailer).to receive(:letter_of_credit_request).with(anything, anything, user).and_return(mailer)
                call_action
              end
              it 'calls `deliver_later` on the result of `InternalMailer#letter_of_credit_request`' do
                expect(mailer).to receive(:deliver_later)
                call_action
              end
              it 'calls `set_titles` with the appropriate title' do
                expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.success.title'))
                call_action
              end
              it 'renders the execute view' do
                call_action
                expect(response.body).to render_template(:execute)
              end
            end
          end
        end
      end
    end

    describe 'GET amend' do
      let(:lc_number) { SecureRandom.hex }
      let(:call_action) { get :amend, current_member_id: member_id, lc_number: lc_number}
      let(:letter_of_credit_request) { instance_double(LetterOfCreditRequest)}
      before do
        allow(LetterOfCreditRequest).to receive(:find_by_lc_number).with(member_id, lc_number, request).and_return(letter_of_credit_request)
        allow(letter_of_credit_request).to receive(:save)
        allow(controller).to receive(:populate_amend_request_view_variables)
      end

      it_behaves_like 'a user required action', :get, :amend
      it_behaves_like 'a LettersOfCreditController action that sets page-specific instance variables with a before filter'
      it_behaves_like 'a LettersOfCreditController action that sets sidebar view variables with a before filter'

      it 'calls the class method`find_by_lc_number`' do
        expect(LetterOfCreditRequest).to receive(:find_by_lc_number).with(member_id, lc_number, request).and_return(letter_of_credit_request)
        call_action
      end
      it 'calls `populate_amend_request_view_variables`' do
        expect(controller).to receive(:populate_amend_request_view_variables)
        call_action
      end
    end

    describe 'POST amend_preview' do
      let(:loc_params) { {sentinel: SecureRandom.hex} }
      let(:call_action) { post :amend_preview, letter_of_credit_request: loc_params }
      let(:amended_amount) { rand(1000000..10000000)}
      let(:amended_expiration_date) { double('amended expiration date')}
      before do
        allow(letter_of_credit_request).to receive(:valid?).and_return(true)
        allow(controller).to receive(:member_contacts)
        allow(letter_of_credit_request).to receive(:amended_amount) .and_return(amended_amount)
        allow(letter_of_credit_request).to receive(:amended_expiration_date) .and_return(amended_amount)
      end

      allow_policy :letters_of_credit, :request?

      it_behaves_like 'a user required action', :post, :amend_preview, letter_of_credit_request: {}
      it_behaves_like 'a LettersOfCreditController action that sets page-specific instance variables with a before filter'
      it_behaves_like 'a LettersOfCreditController action that sets sidebar view variables with a before filter'
      it_behaves_like 'a LettersOfCreditController action that fetches a letter of credit request'
      it_behaves_like 'a LettersOfCreditController action that saves a letter of credit request'
      it 'calls `set_titles` with the appropriate title' do
        expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.request.amend.title'))
        call_action
      end
      it 'sets the attributes of the letter of credit request with the `letter_of_credit_request` params hash' do
        expect(letter_of_credit_request).to receive(:attributes=).with(loc_params)
        call_action
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
      describe 'when the created LetterOfCreditRequest instance is valid' do
        it 'renders the `amend_preview` view' do
          call_action
          expect(response.body).to render_template(:amend_preview)
        end
      end
      describe 'when the created LetterOfCreditRequest instance is invalid' do
        let(:error_message) { instance_double(String) }
        before do
          allow(letter_of_credit_request).to receive(:valid?).and_return(false)
          allow(controller).to receive(:populate_amend_request_view_variables)
          allow(controller).to receive(:prioritized_error_message)
        end

        it 'calls `prioritized_error_message` with the letter of credit request' do
          expect(controller).to receive(:prioritized_error_message).with(letter_of_credit_request)
          call_action
        end
        it 'sets `@error_message` to the result of `prioritized_error_message`' do
          allow(controller).to receive(:prioritized_error_message).and_return(error_message)
          call_action
          expect(assigns[:error_message]).to eq(error_message)
        end
        it 'calls `populate_amend_request_view_variables`' do
          expect(controller).to receive(:populate_amend_request_view_variables)
          call_action
        end
        it 'renders the `new` view' do
          call_action
          expect(response.body).to render_template(:amend)
        end
      end
    end

    describe 'POST amend_execute' do
      let(:rm) {{
        email: SecureRandom.hex,
        phone_number: SecureRandom.hex
      }}
      let(:name) { double('name') }
      let(:user) { instance_double(User, display_name: name, accepted_terms?: true, id: nil) }
      let(:securid_status) { double('some status') }
      let(:call_action) { post :amend_execute }

      before do
        allow(controller).to receive(:member_contacts).and_return({rm: rm})
        allow(controller).to receive(:securid_perform_check).and_return(securid_status)
      end

      allow_policy :letters_of_credit, :request?

      it_behaves_like 'a user required action', :post, :amend_execute
      it_behaves_like 'a LettersOfCreditController action that sets page-specific instance variables with a before filter'
      it_behaves_like 'a LettersOfCreditController action that sets sidebar view variables with a before filter'
      it_behaves_like 'a LettersOfCreditController action that fetches a letter of credit request'
      it_behaves_like 'a LettersOfCreditController action that saves a letter of credit request'

      shared_examples 'an unsuccessful execution' do
        it 'calls `set_titles` with the Preview title' do
          expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.request.amend.title'))
          call_action
        end
        it 'renders the `preview` view' do
          call_action
          expect(response.body).to render_template(:amend_preview)
        end
      end

      context 'when the requester is not permitted to execute the letter of credit amendment' do
        deny_policy :letters_of_credit, :amend_execute?

        it_behaves_like 'an unsuccessful execution'
        it 'sets `@error_message` to the not-authorized message' do
          call_action
          expect(assigns[:error_message]).to eq(I18n.t('letters_of_credit.request.amend.errors.not_authorized'))
        end
      end

      context 'when the requester is permitted to execute the letter of credit amendment' do
        allow_policy :letters_of_credit, :amend_execute?

        it 'performs a securid check' do
          expect(controller).to receive(:securid_perform_check)
          call_action
        end

        context 'when the session is not elevated' do
          before { allow(controller).to receive(:session_elevated?).and_return(false) }

          it_behaves_like 'an unsuccessful execution'
          it 'sets `@securid_status` to the result of `securid_perform_check`' do
            call_action
            expect(assigns[:securid_status]).to eq(securid_status)
          end
        end

        context 'when the session is elevated' do
          before { allow(controller).to receive(:session_elevated?).and_return(true) }

          shared_examples 'a letter of credit amendment request with a generic error' do

            it_behaves_like 'an unsuccessful execution'
            it 'sets `@error_message` to the generic error message' do
              call_action
              expect(assigns[:error_message]).to eq(I18n.t('letters_of_credit.errors.generic_html', rm_email: rm[:email], rm_phone_number: rm[:phone_number]))
            end
          end

          context 'when the letter of credit request is not valid' do
            before { allow(letter_of_credit_request).to receive(:valid?).and_return(false) }
            it_behaves_like 'a letter of credit amendment request with a generic error'
          end
          context 'when the letter of credit request is valid' do
            before { allow(letter_of_credit_request).to receive(:valid?).and_return(true) }

            context 'when the execution of the letter of credit request succeeds' do
              let(:letter_of_credit_json) { double('loc as json') }
              let(:mailer) { double('mailer', deliver_later: nil) }
              before do
                allow(letter_of_credit_request).to receive(:amend_execute).and_return(true)
                allow(MemberMailer).to receive(:letter_of_credit_request_amendment).and_return(mailer)
              end

              it 'converts the letter of credit request to JSON' do
                expect(letter_of_credit_request).to receive(:to_json)
                call_action
              end
              it 'calls `InternalMailer#letter_of_credit_request` with the current_member_id' do
                expect(MemberMailer).to receive(:letter_of_credit_request_amendment).with(member_id, any_args).and_return(mailer)
                call_action
              end
              it 'calls `InternalMailer#letter_of_credit_request` with the letter of credit as JSON' do
                allow(letter_of_credit_request).to receive(:to_json).and_return(letter_of_credit_json)
                expect(MemberMailer).to receive(:letter_of_credit_request_amendment).with(anything, letter_of_credit_json, any_args).and_return(mailer)
                call_action
              end
              it 'calls `InternalMailer#letter_of_credit_request` with the current_user' do
                allow(controller).to receive(:current_user).and_return(user)
                expect(MemberMailer).to receive(:letter_of_credit_request_amendment).with(anything, anything, user).and_return(mailer)
                call_action
              end
              it 'calls `deliver_later` on the result of `InternalMailer#letter_of_credit_request`' do
                expect(mailer).to receive(:deliver_later)
                call_action
              end
              it 'calls `set_titles` with the appropriate title' do
                expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.request.amend.success.title'))
                call_action
              end
              it 'renders the execute view' do
                call_action
                expect(response.body).to render_template(:amend_execute)
              end
            end
          end
        end
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
      let(:now) { Time.zone.now }
      let(:cutoff_time) { Time.zone.parse(LetterOfCreditRequest::ISSUE_DATE_TIME_RESTRICTION) }
      let(:weekends_and_holidays) { instance_double(Array) }
      let(:calendar_service) { instance_double(CalendarService, find_next_business_day: nil) }
      let(:call_method) { subject.send(:date_restrictions) }

      before do
        allow(Time.zone).to receive(:today).and_return(today)
        allow(Time.zone).to receive(:now).and_return(now)
        allow(CalendarService).to receive(:new).and_return(calendar_service)
        allow(controller).to receive(:weekends_and_holidays)
      end

      it 'creates a new instance of the CalendarService with the request as an arg' do
        expect(CalendarService).to receive(:new).with(request).and_return(calendar_service)
        call_method
      end
      it 'parses the LetterOfCreditRequest::ISSUE_DATE_TIME_RESTRICTION to create an ActiveRecord::TimeWithZone object' do
        expect(Time.zone).to receive(:parse).with(LetterOfCreditRequest::ISSUE_DATE_TIME_RESTRICTION).and_call_original
        call_method
      end
      shared_examples 'it bases other dates off a given start date' do |day|
        let(:start_date) { day == :today ? today : today + 1.day }
        let(:max_date) { start_date + LetterOfCreditRequest::EXPIRATION_MAX_DATE_RESTRICTION }
        it "calls `find_next_business_day` on the service instance with #{day} and a 1.day step" do
          expect(calendar_service).to receive(:find_next_business_day).with(start_date, 1.day)
          call_method
        end
        describe 'the returned hash' do
          it 'has a `min_date` that is the result of calling `find_next_business_day` on the calendar service instance' do
            min_date = instance_double(Date)
            allow(calendar_service).to receive(:find_next_business_day).and_return(min_date)
            call_method
            expect(call_method[:min_date]).to eq(min_date)
          end
          it "has an `expiration_max_date` of #{day} plus the `LetterOfCreditRequest::EXPIRATION_MAX_DATE_RESTRICTION`" do
            expect(call_method[:expiration_max_date]).to eq(max_date)
          end
          it "has an `issue_max_date` of #{day} plus the `LetterOfCreditRequest::ISSUE_MAX_DATE_RESTRICTION`" do
            expect(call_method[:issue_max_date]).to eq(start_date + LetterOfCreditRequest::ISSUE_MAX_DATE_RESTRICTION)
          end
          describe 'the `invalid_dates` array' do
            it "calls `weekends_and_holidays` with #{day} as the start_date arg" do
              expect(controller).to receive(:weekends_and_holidays).with(start_date: start_date, end_date: anything, calendar_service: anything)
              call_method
            end
            it "calls `weekends_and_holidays` with a date #{LetterOfCreditRequest::EXPIRATION_MAX_DATE_RESTRICTION} from #{day} as the end_date arg" do
              expect(controller).to receive(:weekends_and_holidays).with(start_date: anything, end_date: (start_date + LetterOfCreditRequest::EXPIRATION_MAX_DATE_RESTRICTION), calendar_service: anything)
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
      context 'when the current time is less than the LetterOfCreditRequest::ISSUE_DATE_TIME_RESTRICTION' do
        before { allow(Time.zone).to receive(:now).and_return(cutoff_time - 1.hour, now) }
        it_behaves_like 'it bases other dates off a given start date', :today
      end
      context 'when the current time is equal to the LetterOfCreditRequest::ISSUE_DATE_TIME_RESTRICTION' do
        before { allow(Time.zone).to receive(:now).and_return(cutoff_time, now) }
        it_behaves_like 'it bases other dates off a given start date', :today
      end
      context 'when the current time is greater than the LetterOfCreditRequest::ISSUE_DATE_TIME_RESTRICTION' do
        before { allow(Time.zone).to receive(:now).and_return(cutoff_time + 1.hour, now) }
        it_behaves_like 'it bases other dates off a given start date', :tomorrow
      end
    end

    describe '`populate_new_request_view_variables`' do
      let(:call_method) { controller.send(:populate_new_request_view_variables) }
      let(:beneficiary_service) { instance_double(BeneficiariesService, beneficiaries: []) }
      before do
        allow(controller).to receive(:date_restrictions)
        allow(controller).to receive(:letter_of_credit_request).and_return(letter_of_credit_request)
        allow(BeneficiariesService).to receive(:new).and_return(beneficiary_service)
      end

      it 'calls `set_titles` with its title' do
        expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.request.title'))
        call_method
      end
      describe '`@beneficiary_dropdown_options`' do
        let(:beneficiaries) {[
          {name: 'Here''s A Beneficiary'},
          {name: 'Yet Another Beneficiary'},
          {name: 'And Here''s Another Beneficiary'}
        ]}
        let(:sorted_beneficiaries) {[
          {name: 'And Here''s Another Beneficiary'},
          {name: 'Here''s A Beneficiary'},
          {name: 'Yet Another Beneficiary'}
        ]}

        it 'creates a new instance of `BeneficiariesService` with the request' do
          expect(BeneficiariesService).to receive(:new).with(request).and_return(beneficiary_service)
          call_method
        end
        it 'fetches `all` of the beneficiaries from the service' do
          expect(beneficiary_service).to receive(:beneficiaries).and_return([])
          call_method
        end
        it 'is an array containing arrays of beneficiary names sorted in ascending order by name' do
          allow(beneficiary_service).to receive(:beneficiaries).and_return(beneficiaries)
          matching_array = sorted_beneficiaries.collect{|x| [x[:name], x[:name]]}
          call_method
          expect(assigns[:beneficiary_dropdown_options]).to eq(matching_array)
        end
        describe '`@beneficiary_dropdown_default`' do
          it 'calls `letter_of_credit_request`' do
            expect(controller).to receive(:letter_of_credit_request).and_return(letter_of_credit_request)
            call_method
          end
          it 'calls `beneficiary_name` on the letter of credit request' do
            expect(letter_of_credit_request).to receive(:beneficiary_name)
            call_method
          end
          context 'when the letter_of_credit_request already has a beneficiary name' do
            let(:beneficiary_name) { double('some name') }

            it 'sets `@beneficiary_dropdown_default` to the beneficiary name' do
              allow(letter_of_credit_request).to receive(:beneficiary_name).and_return(beneficiary_name)
              allow(beneficiary_service).to receive(:beneficiaries).and_return(beneficiaries)
              call_method
              expect(assigns[:beneficiary_dropdown_default]).to eq(beneficiary_name)
            end
          end
          context 'when the beneficiary_name of the letter_of_credit_request is nil' do
            it 'sets `@beneficiary_dropdown_default` to `No Beneficiary on File`' do
              call_method
              expect(assigns[:beneficiary_dropdown_default]).to eq('No Beneficiary on File')
            end
            it 'sets `@no_beneficiaries` to true' do
              call_method
              expect(assigns[:no_beneficiaries]).to eq(true)
            end
          end
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

    describe '`populate_amend_request_view_variables`' do
      let(:call_method) { controller.send(:populate_amend_request_view_variables) }
      before do
        allow(controller).to receive(:date_restrictions)
        allow(controller).to receive(:letter_of_credit_request).and_return(letter_of_credit_request)
      end

      it 'calls `set_titles` with its title' do
        expect(controller).to receive(:set_titles).with(I18n.t('letters_of_credit.request.amend.title'))
        call_method
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

    describe '`letter_of_credit_request`' do
      let(:call_method) { controller.send(:letter_of_credit_request) }

      context 'when the `@letter_of_credit_request` instance variable already exists' do
        before { controller.instance_variable_set(:@letter_of_credit_request, letter_of_credit_request) }

        it 'does not create a new `LetterOfCreditRequest`' do
          expect(LetterOfCreditRequest).not_to receive(:new)
          call_method
        end
        it 'returns the existing `@letter_of_credit_request`' do
          expect(call_method).to eq(letter_of_credit_request)
        end
      end
      context 'when the `@letter_of_credit_request` instance variable does not yet exist' do
        before { allow(LetterOfCreditRequest).to receive(:new).and_return(letter_of_credit_request) }

        it 'creates a new `LetterOfCreditRequest` with the current_member_id and request' do
          expect(LetterOfCreditRequest).to receive(:new).with(member_id, request)
          call_method
        end
        it 'sets `@letter_of_credit_request` to the new LetterOfCreditRequest instance' do
          call_method
          expect(controller.instance_variable_get(:@letter_of_credit_request)).to eq(letter_of_credit_request)
        end
        it 'returns the newly created `@letter_of_credit_request`' do
          expect(call_method).to eq(letter_of_credit_request)
        end
      end
      it 'adds the current user to the owners list' do
        allow(LetterOfCreditRequest).to receive(:new).and_return(letter_of_credit_request)
        expect(letter_of_credit_request.owners).to receive(:add).with(subject.current_user.id)
        call_method
      end
    end

    describe '`fetch_letter_of_credit_request`' do
      let(:request) { double('request', params: {letter_of_credit_request: {id: id}}) }
      let(:call_method) { controller.send(:fetch_letter_of_credit_request) }
      before { allow(subject).to receive(:authorize) }
      shared_examples 'it checks the modify authorization' do
        it 'checks if the current user is allowed to modify the advance' do
          expect(subject).to receive(:authorize).with(letter_of_credit_request, :modify?)
          call_method
        end
        it 'raises any errors raised by checking to see if the user is authorized to modify the advance' do
          error = Pundit::NotAuthorizedError
          allow(subject).to receive(:authorize).and_raise(error)
          expect{ call_method }.to raise_error(error)
        end
      end
      context 'when there is an `id` in the `letter_of_credit_request` params hash' do
        let(:id) { double('id') }
        before do
          allow(controller).to receive(:request).and_return(request)
          allow(LetterOfCreditRequest).to receive(:find).and_return(letter_of_credit_request)
        end
        it_behaves_like 'it checks the modify authorization'
        it 'calls `LetterOfCreditRequest#find` with the id and the request' do
          expect(LetterOfCreditRequest).to receive(:find).with(id, request)
          call_method
        end
        it 'sets `@letter_of_credit_request` to the result of `LetterOfCreditRequest#find`' do
          call_method
          expect(controller.instance_variable_get(:@letter_of_credit_request)).to eq(letter_of_credit_request)
        end
        it 'returns the found request' do
          expect(call_method).to eq(letter_of_credit_request)
        end
      end
      context 'when there is no `id` in the `letter_of_credit_request` params hash' do
        before { allow(controller).to receive(:letter_of_credit_request).and_return(letter_of_credit_request) }
        it_behaves_like 'it checks the modify authorization'
        it 'calls `letter_of_credit_request` method' do
          expect(controller).to receive(:letter_of_credit_request)
          call_method
        end
        it 'sets `@letter_of_credit_request` to the result of `letter_of_credit_request`' do
          call_method
          expect(controller.instance_variable_get(:@letter_of_credit_request)).to eq(letter_of_credit_request)
        end
        it 'returns the result of `letter_of_credit_request`' do
          expect(call_method).to eq(letter_of_credit_request)
        end
      end
    end

    describe '`save_letter_of_credit_request`' do
      let(:call_method) { controller.send(:save_letter_of_credit_request) }
      context 'when the `@letter_of_credit_request` instance variable exists' do
        before { controller.instance_variable_set(:@letter_of_credit_request, letter_of_credit_request) }

        it 'calls `save` on the @letter_of_credit_request' do
          expect(letter_of_credit_request).to receive(:save)
          call_method
        end
        it 'returns the result of calling `save`' do
          save_result = double('result')
          allow(letter_of_credit_request).to receive(:save).and_return(save_result)
          expect(call_method).to eq(save_result)
        end
      end
      context 'when the `@letter_of_credit_request` instance variable does not exist' do
        it 'returns nil' do
          expect(call_method).to be nil
        end
      end
    end

    describe '`beneficiary_request`' do
      let(:call_method) { controller.send(:beneficiary_request) }

      context 'when the `@beneficiary_request` instance variable already exists' do
        before { controller.instance_variable_set(:@beneficiary_request, beneficiary_request) }

        it 'does not create a new `BeneficiaryRequest`' do
          expect(BeneficiaryRequest).not_to receive(:new)
          call_method
        end
        it 'returns the existing `@beneficiary_request`' do
          expect(call_method).to eq(beneficiary_request)
        end
      end
      context 'when the `@beneficiary_request` instance variable does not yet exist' do
        before { allow(BeneficiaryRequest).to receive(:new).and_return(beneficiary_request) }

        it 'creates a new `BeneficiaryRequest` with the current_member_id and request' do
          expect(BeneficiaryRequest).to receive(:new).with(member_id, request)
          call_method
        end
        it 'sets `@beneficiary_request` to the new BeneficiaryRequest instance' do
          call_method
          expect(controller.instance_variable_get(:@beneficiary_request)).to eq(beneficiary_request)
        end
        it 'returns the newly created `@beneficiary_request`' do
          expect(call_method).to eq(beneficiary_request)
        end
      end
      it 'adds the current user to the owners list' do
        allow(BeneficiaryRequest).to receive(:new).and_return(beneficiary_request)
        expect(beneficiary_request.owners).to receive(:add).with(subject.current_user.id)
        call_method
      end
    end

    describe '`fetch_beneficiary_request`' do
      let(:request) { double('request', params: {beneficiary_request: {id: id}}) }
      let(:call_method) { controller.send(:fetch_beneficiary_request) }
      before { allow(subject).to receive(:authorize) }
      shared_examples 'it checks the add_beneficiary authorization' do
        it 'checks if the current user is allowed to add_beneficiary the advance' do
          expect(subject).to receive(:authorize).with(beneficiary_request, :add_beneficiary?)
          call_method
        end
        it 'raises any errors raised by checking to see if the user is authorized to add_beneficiary the advance' do
          error = Pundit::NotAuthorizedError
          allow(subject).to receive(:authorize).and_raise(error)
          expect{ call_method }.to raise_error(error)
        end
      end
      context 'when there is an `id` in the `beneficiary_request` params hash' do
        let(:id) { double('id') }
        before do
          allow(controller).to receive(:request).and_return(request)
          allow(BeneficiaryRequest).to receive(:find).and_return(beneficiary_request)
        end
        it_behaves_like 'it checks the add_beneficiary authorization'
        it 'calls `BeneficiaryRequest#find` with the id and the request' do
          expect(BeneficiaryRequest).to receive(:find).with(id, request)
          call_method
        end
        it 'sets `@beneficiary_request` to the result of `BeneficiaryRequest#find`' do
          call_method
          expect(controller.instance_variable_get(:@beneficiary_request)).to eq(beneficiary_request)
        end
        it 'returns the found request' do
          expect(call_method).to eq(beneficiary_request)
        end
      end
      context 'when there is no `id` in the `beneficiary_request` params hash' do
        before { allow(controller).to receive(:beneficiary_request).and_return(beneficiary_request) }
        it_behaves_like 'it checks the add_beneficiary authorization'
        it 'calls `beneficiary_request` method' do
          expect(controller).to receive(:beneficiary_request)
          call_method
        end
        it 'sets `@beneficiary_request` to the result of `beneficiary_request`' do
          call_method
          expect(controller.instance_variable_get(:@beneficiary_request)).to eq(beneficiary_request)
        end
        it 'returns the result of `beneficiary_request`' do
          expect(call_method).to eq(beneficiary_request)
        end
      end
    end

    describe '`save_beneficiary_request`' do
      let(:call_method) { controller.send(:save_beneficiary_request) }
      context 'when the `@beneficiary_request` instance variable exists' do
        before { controller.instance_variable_set(:@beneficiary_request, beneficiary_request) }

        it 'calls `save` on the @beneficiary_request' do
          expect(beneficiary_request).to receive(:save)
          call_method
        end
        it 'returns the result of calling `save`' do
          save_result = double('result')
          allow(beneficiary_request).to receive(:save).and_return(save_result)
          expect(call_method).to eq(save_result)
        end
      end
      context 'when the `@beneficiary_request` instance variable does not exist' do
        it 'returns nil' do
          expect(call_method).to be nil
        end
      end
    end


    describe '`prioritized_error_message`' do
      let(:max_term) { rand(12..120) }
      let(:remaining_bc) { rand(1000..999999) }
      let(:remaining_financing) { rand(1000..999999) }
      let(:letter_of_credit) { instance_double(LetterOfCreditRequest, errors: nil, standard_borrowing_capacity: remaining_bc, max_term: max_term, remaining_financing_available: remaining_financing)}
      let(:call_method) { subject.send(:prioritized_error_message, letter_of_credit) }

      context 'when there are no errors' do
        it 'returns nil' do
          expect(call_method).to be nil
        end
      end
      context 'when there are errors' do
        let(:error_message) { instance_double(String) }
        let(:errors) { instance_double(ActiveModel::Errors, :added? => nil, first: [SecureRandom.hex, error_message]) }
        before do
          allow(letter_of_credit).to receive(:errors).and_return(errors)
          allow(errors).to receive(:added?)
        end
        it 'checks to see if an `amount` `exceeds_financing_availability` error has been added' do
          expect(errors).to receive(:added?).with(:amount, :exceeds_financing_availability)
          call_method
        end
        it 'checks to see if an `amount` `exceeds_borrowing_capacity` error has been added' do
          expect(errors).to receive(:added?).with(:amount, :exceeds_borrowing_capacity)
          call_method
        end
        it 'checks to see if an `expiration_date` `after_max_term` error has been added' do
          expect(errors).to receive(:added?).with(:expiration_date, :after_max_term)
          call_method
        end
        describe 'when the errors contain an `amount` `exceeds_financing_availability` error' do
          before { allow(errors).to receive(:added?).with(:amount, :exceeds_financing_availability).and_return(true) }
          it 'reads the remaining_financing_available attribute of the letter_of_credit_request' do
            expect(letter_of_credit).to receive(:remaining_financing_available).and_return(remaining_financing)
            call_method
          end
          it 'formats the remaining financing available' do
            expect(subject).to receive(:fhlb_formatted_currency_whole).with(remaining_financing, html: false)
            call_method
          end
          it 'adds an error message containing the formatted remaining financing available' do
            formatted_remaining = SecureRandom.hex
            allow(controller).to receive(:fhlb_formatted_currency_whole).and_return(formatted_remaining)
            expect(call_method).to eq(I18n.t('letters_of_credit.errors.exceeds_financing_availability', financing_availability: formatted_remaining))
          end
        end
        describe 'when the errors contain an `amount` `exceeds_borrowing_capacity` error' do
          before { allow(errors).to receive(:added?).with(:amount, :exceeds_borrowing_capacity).and_return(true) }
          it 'reads the standard_borrowing_capacity attribute of the letter_of_credit_request' do
            expect(letter_of_credit).to receive(:standard_borrowing_capacity).and_return(remaining_bc)
            call_method
          end
          it 'formats the remaining standard borrowing capacity' do
            expect(subject).to receive(:fhlb_formatted_currency_whole).with(remaining_bc, html: false)
            call_method
          end
          it 'adds an error message containing the formatted remaining standard borrowing capacity' do
            formatted_capacity = SecureRandom.hex
            allow(controller).to receive(:fhlb_formatted_currency_whole).and_return(formatted_capacity)
            expect(call_method).to eq(I18n.t('letters_of_credit.errors.exceeds_borrowing_capacity', borrowing_capacity: formatted_capacity))
          end
        end
        describe 'when the errors contain an `expiration_date` `after_max_term` error' do
          before { allow(errors).to receive(:added?).with(:expiration_date, :after_max_term).and_return(true) }
          it 'reads the max_term attribute of the letter_of_credit_request' do
            expect(letter_of_credit).to receive(:max_term).and_return(max_term)
            call_method
          end
          it 'adds an error message containing the max term' do
            expect(call_method).to eq(I18n.t('letters_of_credit.errors.after_max_term', max_term: max_term))
          end
        end
        describe 'when the errors do not contain an `amount` `exceeds_borrowing_capacity` error' do
          it 'returns the first error message in the error array' do
            expect(call_method).to eq(error_message)
          end
        end
      end
    end
  end
end