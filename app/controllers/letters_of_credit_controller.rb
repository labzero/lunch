class LettersOfCreditController < ApplicationController
  include ReportsHelper
  include CustomFormattingHelper
  include ContactInformationHelper
  include SidebarHelper
  include DatePickerHelper

  STATES = [ ["AK", "Alaska"],
             ["AL", "Alabama"],
             ["AR", "Arkansas"],
             ["AZ", "Arizona"],
             ["CA", "California"],
             ["CO", "Colorado"],
             ["CT", "Connecticut"],
             ["DC", "District of Columbia"],
             ["DE", "Delaware"],
             ["FL", "Florida"],
             ["GA", "Georgia"],
             ["HI", "Hawaii"],
             ["IA", "Iowa"],
             ["ID", "Idaho"],
             ["IL", "Illinois"],
             ["IN", "Indiana"],
             ["KS", "Kansas"],
             ["KY", "Kentucky"],
             ["LA", "Louisiana"],
             ["MA", "Massachusetts"],
             ["MD", "Maryland"],
             ["ME", "Maine"],
             ["MI", "Michigan"],
             ["MN", "Minnesota"],
             ["MO", "Missouri"],
             ["MS", "Mississippi"],
             ["MT", "Montana"],
             ["NC", "North Carolina"],
             ["ND", "North Dakota"],
             ["NE", "Nebraska"],
             ["NH", "New Hampshire"],
             ["NJ", "New Jersey"],
             ["NM", "New Mexico"],
             ["NV", "Nevada"],
             ["NY", "New York"],
             ["OH", "Ohio"],
             ["OK", "Oklahoma"],
             ["OR", "Oregon"],
             ["PA", "Pennsylvania"],
             ["RI", "Rhode Island"],
             ["SC", "South Carolina"],
             ["SD", "South Dakota"],
             ["TN", "Tennessee"],
             ["TX", "Texas"],
             ["UT", "Utah"],
             ["VI", "Virgin Islands"],
             ["VT", "Vermont"],
             ["WA", "Washington"],
             ["WI", "Wisconsin"],
             ["WV", "West Virginia"],
             ["WY", "Wyoming"] ].freeze

  LC_INSTRUMENT_TYPE = 'LC'.freeze

  before_action do
    set_active_nav(:letters_of_credit)
    @html_class ||= 'white-background'
  end

  before_action except: [:manage] do
    @profile = sanitized_profile
    @contacts = member_contacts
    authorize :letters_of_credit, :request?
  end

  before_action only: [:new, :manage] do
    member = MembersService.new(request).member(current_member_id)
    raise ActionController::RoutingError.new("There has been an error and LettersOfCreditController#view has encountered nil calling MembersService. Check error logs.") if member.nil?
    @lc_agreement_flag = member[:customer_lc_agreement_flag]
  end

  before_action :fetch_beneficiary_request, only: [:beneficiary, :beneficiary_new]
  after_action :save_beneficiary_request, only: [:beneficiary]

  before_action :fetch_letter_of_credit_request, except: [:manage, :view, :amend, :beneficiary, :beneficiary_new]
  after_action :save_letter_of_credit_request, except: [:manage, :view, :amend, :beneficiary, :beneficiary_new]

  # GET
  def manage
    set_titles(t('letters_of_credit.manage.title'))
    member_balances = MemberBalanceService.new(current_member_id, request)
    historic_locs = member_balances.letters_of_credit
    intraday_locs = member_balances.todays_credit_activity
    raise StandardError, "There has been an error and LettersOfCreditController#manage has encountered nil. Check error logs." if historic_locs.nil? || intraday_locs.nil?
    historic_locs = historic_locs[:credits]
    intraday_locs = intraday_locs.select{ |activity| activity[:instrument_type] == LC_INSTRUMENT_TYPE }
    locs = dedupe_locs(intraday_locs, historic_locs)
    rows = if locs.present?
      sort_report_data(locs, :lc_number).collect do |credit|
        {
          columns: [
            {value: credit[:lc_number], type: nil},
            {value: credit[:beneficiary].try(:truncate, 52, separator: ' ', omission: '..').try(:gsub, /\,..$/, '..'), type: nil},
            {value: credit[:current_par], type: :currency_whole},
            {value: credit[:trade_date], type: :date},
            {value: credit[:maturity_date], type: :date},
            {value: credit[:description], type: nil},
            {value: credit[:maintenance_charge], type: :basis_point},
            {value: t('global.view_pdf'), type: nil},
            {value: credit[:sort_code], type: nil}
          ]
        }
      end
    else
      []
    end
    @table_data = {
      column_headings: [
        t('reports.pages.letters_of_credit.headers.lc_number'),
        t('reports.pages.letters_of_credit.headers.beneficiary'),
        fhlb_add_unit_to_table_header(t('reports.pages.letters_of_credit.headers.current_amount'), '$'),
        t('global.issue_date'),
        t('letters_of_credit.manage.expiration_date'),
        t('reports.pages.letters_of_credit.headers.credit_program'),
        t('reports.pages.letters_of_credit.headers.annual_maintenance_charge'),
        t('global.actions')],
      rows: rows
    }
    @amend_on = feature_enabled?('letters-of-credit-amend')
  end

  # GET
  def new
    populate_new_request_view_variables
  end

  # GET
  def amend
    @letter_of_credit_request = LetterOfCreditRequest.find_by_lc_number(current_member_id,params[:lc_number], request)
    populate_amend_request_view_variables
  end

  # POST
  def amend_preview
    set_titles(t('letters_of_credit.request.amend.title'))
    letter_of_credit_request.attributes = params[:letter_of_credit_request]
    @amended_amount ||= letter_of_credit_request.amended_amount
    @amended_expiration_date ||= letter_of_credit_request.amended_expiration_date
    @session_elevated = session_elevated?
    unless @letter_of_credit_request.valid?
      @error_message = prioritized_error_message(@letter_of_credit_request)
      populate_amend_request_view_variables
      render :amend
    end
  end

  # POST
  def amend_execute
    request_succeeded = false
    if !policy(:letters_of_credit).amend_execute?
      @error_message = t('letters_of_credit.errors.not_authorized')
    else
      securid_status = securid_perform_check
    end
    if !session_elevated?
      @securid_status = securid_status
    elsif letter_of_credit_request.valid?
      # letter_of_credit_request.amend_execute(current_user.display_name)
      set_titles(t('letters_of_credit.request.amend.success.title'))
      MemberMailer.letter_of_credit_request(current_member_id, @letter_of_credit_request.to_json, current_user).deliver_later
      request_succeeded = true
    else
      @error_message = t('letters_of_credit.errors.generic_html', rm_email: @contacts[:rm][:email], rm_phone_number: @contacts[:rm][:phone_number])
    end
    unless request_succeeded
      set_titles(t('letters_of_credit.request.amend.title'))
      render :amend_preview
    end
  end

  # POST
  def preview
    set_titles(t('letters_of_credit.request.title'))
    letter_of_credit_request.attributes = params[:letter_of_credit_request]
    @session_elevated = session_elevated?
    unless @letter_of_credit_request.valid?
      @error_message = prioritized_error_message(@letter_of_credit_request)
      populate_new_request_view_variables
      render :new
    end
  end

  # POST
  def execute
    request_succeeded = false
    if !policy(:letters_of_credit).execute?
      @error_message = t('letters_of_credit.errors.not_authorized')
    else
      securid_status = securid_perform_check
    end
    if !session_elevated?
      @securid_status = securid_status
    elsif letter_of_credit_request.valid? && letter_of_credit_request.execute(current_user.display_name)
      set_titles(t('letters_of_credit.success.title'))
      MemberMailer.letter_of_credit_request(current_member_id, @letter_of_credit_request.to_json, current_user).deliver_later
      request_succeeded = true
    else
      @error_message = t('letters_of_credit.errors.generic_html', rm_email: @contacts[:rm][:email], rm_phone_number: @contacts[:rm][:phone_number])
    end
    unless request_succeeded
      set_titles(t('letters_of_credit.request.title'))
      render :preview
    end
  end

  # GET
  def view
    @letter_of_credit_request = LetterOfCreditRequest.find(params[:letter_of_credit_request][:id], request)
    if params[:export_format] == 'pdf'
      pdf_name = "letter_of_credit_request_#{@letter_of_credit_request.lc_number}.pdf"
      job_status = RenderLetterOfCreditPDFJob.perform_later(current_member_id, action_name, pdf_name, { letter_of_credit_request: {id: letter_of_credit_request.id} }).job_status
      job_status.update_attributes!(user_id: current_user.id)
      render json: {job_status_url: job_status_url(job_status), job_cancel_url: job_cancel_url(job_status)}
    else
      member = MembersService.new(request).member(current_member_id)
      raise ActionController::RoutingError.new("There has been an error and LettersOfCreditController#view has encountered nil calling MembersService. Check error logs.") if member.nil?
      @member_name, @member_fhla = member[:name], member[:fhla_number]
    end
  end

  # GET
  def beneficiary
    set_titles(t('letters_of_credit.beneficiary.add'))
    @states_dropdown = STATES.collect{|state| [state[0].to_s + ' - ' + state[1].to_s, state[0]]}
    @states_dropdown.unshift(t('letters_of_credit.beneficiary.select_state'))
    @states_dropdown_default = @states_dropdown.first
  end

  # POST
  def beneficiary_new
    set_titles(t('letters_of_credit.beneficiary_new.title'))
    beneficiary_request.attributes = params[:beneficiary_request]
    if beneficiary_request.valid?
      MemberMailer.beneficiary_request(request, current_member_id, @beneficiary_request.to_json, current_user).deliver_now
    end
    @created_at = Time.zone.now
    @user_email = current_user.email
  end

  private

  def set_titles(title)
    @title = title
    @page_title = t('global.page_meta_title', title: title)
  end

  def dedupe_locs(intraday_locs, historic_locs)
    deduped_locs = {}
    (intraday_locs + historic_locs).each do |loc|
      if deduped_locs[loc[:lc_number]]
        deduped_locs[loc[:lc_number]][:description] ||= loc[:description] # Intraday LOCs do not currently contain a cica program description
      else
        deduped_locs[loc[:lc_number]] = loc
      end
    end
    deduped_locs.values
  end

  def date_restrictions
    today = Time.zone.today
    calendar_service = CalendarService.new(request)
    start_date = Time.zone.now > Time.zone.parse(LetterOfCreditRequest::ISSUE_DATE_TIME_RESTRICTION) ? today + 1.day : today
    expiration_max_date = start_date + LetterOfCreditRequest::EXPIRATION_MAX_DATE_RESTRICTION
    {
      min_date: calendar_service.find_next_business_day(start_date, 1.day),
      invalid_dates: weekends_and_holidays(start_date: start_date, end_date: expiration_max_date, calendar_service: calendar_service),
      expiration_max_date: expiration_max_date,
      issue_max_date: start_date + LetterOfCreditRequest::ISSUE_MAX_DATE_RESTRICTION
    }
  end

  def populate_new_request_view_variables
    set_titles(t('letters_of_credit.request.title'))
    @beneficiary_dropdown_options = BeneficiariesService.new(request).beneficiaries(current_member_id).collect{|beneficiary| [beneficiary[:name], beneficiary[:name]] }
    @beneficiary_dropdown_default = letter_of_credit_request.beneficiary_name || @beneficiary_dropdown_options.first.try(:last)
    @date_restrictions = date_restrictions
    unless @beneficiary_dropdown_options.first.try(:last)
      @no_beneficiaries = true
      @beneficiary_dropdown_default = t('letters_of_credit.beneficiary.no_beneficiary')
    end
  end

  def populate_amend_request_view_variables
    set_titles(t('letters_of_credit.request.amend.title'))
    @date_restrictions = date_restrictions
  end

  def letter_of_credit_request
    @letter_of_credit_request ||= LetterOfCreditRequest.new(current_member_id, request)
    @letter_of_credit_request.owners.add(current_user.id)
    @letter_of_credit_request
  end

  def fetch_letter_of_credit_request
    letter_of_credit_params = (request.params[:letter_of_credit_request] || {}).with_indifferent_access
    id = letter_of_credit_params[:id]
    @letter_of_credit_request = id ? LetterOfCreditRequest.find(id, request) : letter_of_credit_request
    authorize @letter_of_credit_request, :modify?
    @letter_of_credit_request
  end

  def save_letter_of_credit_request
    @letter_of_credit_request.save if @letter_of_credit_request
  end

  def beneficiary_request
    @beneficiary_request ||= BeneficiaryRequest.new(current_member_id, request)
    @beneficiary_request.owners.add(current_user.id)
    @beneficiary_request
  end

  def fetch_beneficiary_request
    beneficiary_request_params = (request.params[:beneficiary_request] || {}).with_indifferent_access
    id = beneficiary_request_params[:id]
    @beneficiary_request = id ? BeneficiaryRequest.find(id, request) : beneficiary_request
    authorize @beneficiary_request, :add_beneficiary?
    @beneficiary_request
  end

  def save_beneficiary_request
    @beneficiary_request.save if @beneficiary_request
  end

  def prioritized_error_message(letter_of_credit)
    errors = letter_of_credit.errors
    unless errors.blank?
      if errors.added? :amount, :exceeds_financing_availability
        t('letters_of_credit.errors.exceeds_financing_availability', financing_availability: fhlb_formatted_currency_whole(letter_of_credit.remaining_financing_available, html: false))
      elsif errors.added? :amount, :exceeds_borrowing_capacity
        t('letters_of_credit.errors.exceeds_borrowing_capacity', borrowing_capacity: fhlb_formatted_currency_whole(letter_of_credit.standard_borrowing_capacity, html: false))
      elsif errors.added? :expiration_date, :after_max_term
        t('letters_of_credit.errors.after_max_term', max_term: letter_of_credit.max_term)
      else
        errors.first.last
      end
    end
  end
end