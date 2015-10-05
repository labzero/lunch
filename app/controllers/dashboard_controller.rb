class DashboardController < ApplicationController
  include CustomFormattingHelper
  include DashboardHelper

  THRESHOLD_CAPACITY = 35 #this will be set by each client, probably with a default value of 35, and be stored in some as-yet-unnamed db
  ADVANCE_TYPES = [:whole, :agency, :aaa, :aa]
  COLLATERAL_TYPE_MAPPING = {
    whole: I18n.t('dashboard.quick_advance.table.mortgage'),
    agency: I18n.t('dashboard.quick_advance.table.agency'),
    aaa: I18n.t('dashboard.quick_advance.table.aaa'),
    aa: I18n.t('dashboard.quick_advance.table.aa')
  }.freeze
  ADVANCE_TERMS = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']

  before_action only: [:quick_advance_rates, :quick_advance_preview, :quick_advance_perform] do
    authorize :advances, :show?
  end

  before_action only: [:quick_advance_perform, :quick_advance_preview] do
    session['signer_full_name'] ||= EtransactAdvancesService.new(request).signer_full_name(current_user.username)
  end

  def index
    today = Time.zone.now.to_date
    rate_service = RatesService.new(request)
    etransact_service = EtransactAdvancesService.new(request)
    member_balances = MemberBalanceService.new(current_member_id, request)
    members_service = MembersService.new(request)
    current_user_roles

    profile = member_balances.profile

    @previous_activity = [
      [t('dashboard.previous_activity.overnight_vrc'), 44503000, DateTime.new(2014,9,3)],
      [t('dashboard.previous_activity.overnight_vrc'), 39097000, DateTime.new(2014,9,2)],
      [t('dashboard.previous_activity.overnight_vrc'), 37990040, DateTime.new(2014,8,12)],
      [t('dashboard.previous_activity.overnight_vrc'), 39282021, DateTime.new(2014,2,14)]
    ]

    # @account_overview sub-table row format: [title, value, footnote(optional), precision(optional)]
    if !profile
      profile = {
        credit_outstanding: {}
      }
    end

    if members_service.report_disabled?(current_member_id, [MembersService::FINANCING_AVAILABLE_DATA])
      profile[:total_financing_available] = nil
    end

    if members_service.report_disabled?(current_member_id, [MembersService::STA_BALANCE_AND_RATE_DATA, MembersService::STA_DETAIL_DATA])
      profile[:sta_balance] = nil
    end

    if members_service.report_disabled?(current_member_id, [MembersService::CREDIT_OUTSTANDING_DATA])
      profile[:credit_outstanding][:total] = nil
    end

    if members_service.report_disabled?(current_member_id, [MembersService::COLLATERAL_HIGHLIGHTS_DATA])
      profile[:collateral_borrowing_capacity][:remaining] = nil
    end

    if members_service.report_disabled?(current_member_id, [MembersService::FHLB_STOCK_DATA])
      profile[:capital_stock] = nil
    end

    sta_balance = [
      [t('dashboard.your_account.table.balance'), profile[:sta_balance], t('dashboard.your_account.table.balance_footnote')],
    ]

    credit_outstanding = [
      [t('dashboard.your_account.table.credit_outstanding'), profile[:credit_outstanding][:total]]
    ]

    remaining = [
      {title: t('dashboard.your_account.table.remaining.title')},
      [t('dashboard.your_account.table.remaining.available'), profile[:total_financing_available]],
      [t('dashboard.your_account.table.remaining.capacity'), (profile[:collateral_borrowing_capacity] || {})[:remaining]],
      [t('dashboard.your_account.table.remaining.leverage'), (profile[:capital_stock] || {})[:remaining_leverage], nil, 2]
    ]

    @account_overview = {sta_balance: sta_balance, credit_outstanding: credit_outstanding, remaining: remaining}

    @market_overview = [{
      name: 'Test',
      data: members_service.report_disabled?(current_member_id, [MembersService::IRDB_RATES_DATA]) ? nil : rate_service.overnight_vrc
    }]

    borrowing_capacity = members_service.report_disabled?(current_member_id, [MembersService::COLLATERAL_REPORT_DATA]) ? nil : member_balances.borrowing_capacity_summary(today)

    @borrowing_capacity_gauge = if borrowing_capacity
      total_borrowing_capacity = borrowing_capacity[:total_borrowing_capacity]
      guage = {
        total: total_borrowing_capacity,
        mortgages: borrowing_capacity[:standard_credit_totals][:borrowing_capacity],
        aa: borrowing_capacity[:sbc][:collateral][:aa][:total_borrowing_capacity],
        aaa: borrowing_capacity[:sbc][:collateral][:aaa][:total_borrowing_capacity],
        agency: borrowing_capacity[:sbc][:collateral][:agency][:total_borrowing_capacity]
      }
      calculate_gauge_percentages(guage, total_borrowing_capacity, :total)
    else
      calculate_gauge_percentages({total: 0}, 0)
    end
    
    @financing_availability_gauge = if profile[:total_financing_available]
      calculate_gauge_percentages(
        {
          total: profile[:total_financing_available],
          used: profile[:used_financing_availability],
          unused: profile[:collateral_borrowing_capacity][:remaining],
          uncollateralized: profile[:uncollateralized_financing_availability]
        }, profile[:total_financing_available], :total)
    else
      calculate_gauge_percentages({total: 0}, 0)
    end

    current_rate = rate_service.current_overnight_vrc
    @current_overnight_vrc = if current_rate
      current_rate[:rate]
    else
      nil
    end

    @quick_advance_enabled = members_service.quick_advance_enabled_for_member?(current_member_id)
    etransact_status = etransact_service.status
    quick_advance_open = etransact_service.etransact_active?(etransact_status)
    quick_advance_terms = etransact_service.has_terms?(etransact_status)
    @quick_advance_status = (quick_advance_open ? (quick_advance_terms ? :open : :no_terms) : :closed)
    # TODO replace this with the timestamp from the cached quick advance rates timestamp
    date = DateTime.now - 2.hours
    @quick_advance_last_updated = date.strftime("%d %^b %Y, %l:%M %p")
    @contacts = members_service.member_contacts(current_member_id) || {}
    default_image_path = 'placeholder-usericon.svg'
    if @contacts[:rm] && @contacts[:rm][:username]
      rm_image_path = "#{@contacts[:rm][:username].downcase}.jpg"
      @contacts[:rm][:image_url] = Rails.application.assets.find_asset(rm_image_path) ? rm_image_path : default_image_path
    end
    if @contacts[:cam] && @contacts[:cam][:username]
      cam_image_path = "#{@contacts[:cam][:username].downcase}.jpg" 
      @contacts[:cam][:image_url] = Rails.application.assets.find_asset(cam_image_path) ? cam_image_path : default_image_path
    end
  end

  def quick_advance_rates
    etransact_service = EtransactAdvancesService.new(request)
    @quick_advances_active = etransact_service.etransact_active?
    @rate_data = RatesService.new(request).quick_advance_rates(current_member_id)
    @advance_terms = ADVANCE_TERMS
    @advance_types = ADVANCE_TYPES
    render layout: false
  end

  def quick_advance_preview
    @current_member_name = current_member_name
    @preview = true
    etransact_service = EtransactAdvancesService.new(request)
    check = etransact_service.check_limits(current_member_id, params[:amount].to_f, params[:advance_term])
    preview = EtransactAdvancesService.new(request).quick_advance_validate(current_member_id, params[:amount].to_f, params[:advance_type], params[:advance_term], params[:advance_rate].to_f, params[:check_capstock], session['signer_full_name'])
    advance_request_parameters(preview)
    populate_advance_request_view_parameters
    if check[:status] == 'pass'
      if preview[:status] && preview[:status].include?('CapitalStockError')
        preview_success = false
        preview_error = false
        @advance_amount = params[:amount].to_f if params[:amount]
        @original_amount = params[:amount].to_f if params[:amount]
        response_html = render_to_string :quick_advance_capstock, layout: false
      elsif preview[:status] && (preview[:status].include?('GrossUpError') || preview[:status].include?('ExceptionError'))
        preview_success = false
        preview_error = true
        @error_message = check[:status].to_sym
        response_html = render_to_string :quick_advance_error, layout: false
      elsif preview[:status] && preview[:status].include?('CreditError')
        preview_success = false
        preview_error = true
        @advance_amount = params[:amount].to_f if params[:amount]
        @error_message = :credit
        response_html = render_to_string :quick_advance_error, layout: false
      elsif preview[:status] && preview[:status].include?('CollateralError')
        preview_success = false
        preview_error = true
        @error_message = :collateral
        response_html = render_to_string :quick_advance_error, layout: false
      elsif preview[:status] && preview[:status].include?('ExceedsTotalDailyLimitError')
        preview_success = false
        preview_error = true
        @advance_amount = params[:amount].to_f if params[:amount]
        @error_message = :total_daily_limit
        response_html = render_to_string :quick_advance_error, layout: false
      else
        checked_rate = check_advance_rate(etransact_service, @advance_type_raw, @advance_term, @advance_rate)
        if checked_rate[:stale_rate]
          preview_success = false
          preview_error = true
          response_html = render_to_string :quick_advance_error, layout: false
        else
          preview_success = true
          preview_error = false
          @original_amount = @advance_amount.to_f
          @stock = params[:stock].to_f if params[:stock]
          @session_elevated = session_elevated?
          @advance_rate = checked_rate[:advance_rate]
          @old_rate = checked_rate[:old_rate]
          @rate_changed = checked_rate[:rate_changed]
          advance_request_timestamp!
          response_html = render_to_string layout: false
        end
      end
    else
      preview_success = false
      preview_error = true
      @error_message = check[:status].try(:to_sym)
      @min_amount = check[:low]
      @max_amount = check[:high]
      response_html = render_to_string :quick_advance_error, layout: false
    end
    render json: {preview_success: preview_success, preview_error: preview_error, html: response_html, authorized_amount: @authorized_amount, gross_amount: @gross_amount, net_stock_required: @net_stock_required, gross_net_stock_required: @gross_net_stock_required, original_amount: @original_amount}
  end

  def quick_advance_perform
    unless session_elevated?
      securid = SecurIDService.new(current_user.username)
      begin
        securid.authenticate(params[:securid_pin], params[:securid_token])
        session_elevate! if securid.authenticated?
        securid_status = securid.status
      rescue SecurIDService::InvalidPin => e
        securid_status = 'invalid_pin'
      rescue SecurIDService::InvalidToken => e
        securid_status = 'invalid_token'
      end
    else
      securid_status = :authenticated
    end
    advance_success = false
    response_html = false
    if session_elevated?
      expired_rate = advance_request_expired?
      if expired_rate
        advance_success = false
        populate_advance_request_view_parameters
        @error_message = :rate_expired
        response_html = render_to_string :quick_advance_error, layout: false
      else
        confirmation = EtransactAdvancesService.new(request).quick_advance_execute(current_member_id, params[:amount].to_f, params[:advance_type], params[:advance_term], params[:advance_rate].to_f, session['signer_full_name'])
        if confirmation
          advance_request_parameters(confirmation)
          advance_success = true
          populate_advance_request_view_parameters
          @stock = params[:stock].to_f if params[:stock]
          response_html = render_to_string layout: false
        end
      end
    end
    render json: {securid: securid_status, advance_success: advance_success, html: response_html}
  end

  def current_overnight_vrc
    etransact_service = EtransactAdvancesService.new(request)
    response = RatesService.new(request).current_overnight_vrc || {}
    response[:quick_advances_active] = etransact_service.etransact_active?
    render json: response
  end

  private

  def advance_request_expired?
    etransact_service = EtransactAdvancesService.new(request)
    settings = etransact_service.settings
    raise 'No RateTimeout setting found' unless settings
    timeout = settings[:rate_timeout]
    session[:advance_request] ||= {}
    session[:advance_request]['timestamp'].present? && (Time.zone.now - session[:advance_request]['timestamp'].to_datetime) >= timeout
  end

  def populate_advance_request_view_parameters
    advance_params = advance_request_parameters || {}
    @authorized_amount = advance_params[:authorized_amount]
    @exception_message = advance_params[:exception_message]
    @cumulative_stock_required = advance_params[:cumulative_stock_required]
    @current_trade_stock_required = advance_params[:current_trade_stock_required]
    @pre_trade_stock_required = advance_params[:pre_trade_stock_required]
    @net_stock_required = advance_params[:net_stock_required]
    @gross_amount = advance_params[:gross_amount]
    @gross_cumulative_stock_required = advance_params[:gross_cumulative_stock_required]
    @gross_current_trade_stock_required = advance_params[:gross_current_trade_stock_required]
    @gross_pre_trade_stock_required = advance_params[:gross_pre_trade_stock_required]
    @gross_net_stock_required = advance_params[:gross_net_stock_required]
    @advance_amount = advance_params[:advance_amount].try(:to_f)
    @advance_description = get_description_from_advance_term(advance_params[:advance_term])
    @advance_type_raw = advance_params[:advance_type]
    @advance_program = get_program_from_advance_type(advance_params[:advance_type])
    @advance_type = get_type_from_advance_type(advance_params[:advance_type])
    @interest_day_count = advance_params[:interest_day_count]
    @payment_on = advance_params[:payment_on]
    @advance_term = advance_params[:advance_term]
    @funding_date = advance_params[:funding_date]
    @maturity_date = advance_params[:maturity_date]
    @advance_rate = advance_params[:advance_rate].try(:to_f)
    @initiated_at = advance_params[:initiated_at]
    @advance_number = advance_params[:confirmation_number]
    @collateral_type = get_collateral_type_from_advance_type(advance_params[:advance_type])
  end

  def advance_request_parameters(advance_parameters=nil)
    session[:advance_request] ||= {}
    session[:advance_request]['parameters'] = advance_parameters if advance_parameters
    session[:advance_request]['parameters'].try(:with_indifferent_access)
  end

  def advance_request_timestamp!
    session[:advance_request] ||= {}
    session[:advance_request]['timestamp'] = Time.zone.now
  end

  def calculate_gauge_percentages(gauge_hash, total, excluded_keys=[])
    excluded_keys = Array.wrap(excluded_keys)
    largest_display_percentage_key = nil
    largest_display_percentage = 0
    total_display_percentage = 0
    new_gauge_hash = gauge_hash.deep_dup

    gauge_hash.each do |key, value|
      percentage = total > 0 ? (value.to_f / total) * 100 : 0

      display_percentage = percentage.ceil
      display_percentage += display_percentage % 2

      new_gauge_hash[key] = {
        amount: value,
        percentage: percentage,
        display_percentage: display_percentage
      }
      unless excluded_keys.include?(key)
        if display_percentage >= largest_display_percentage
          largest_display_percentage = display_percentage
          largest_display_percentage_key = key
        end
        total_display_percentage += display_percentage
      end
    end
    new_gauge_hash[largest_display_percentage_key][:display_percentage] = (100 - (total_display_percentage - largest_display_percentage))
    new_gauge_hash
  end

  def get_description_from_advance_term(advance_term)
    if advance_term
      advance_term = advance_term.upcase
      case advance_term
        when 'OVERNIGHT', 'OPEN'
          I18n.t('dashboard.quick_advance.vrc_title')
        else
          I18n.t('dashboard.quick_advance.frc_title')
      end
    end
  end

  def get_program_from_advance_type(advance_type)
    if advance_type
      advance_type = advance_type.upcase.gsub(/\s+/, "")
      case advance_type
        when 'WHOLELOAN', 'WHOLE'
          I18n.t('dashboard.quick_advance.table.axes_labels.standard')
        when 'SBC-AGENCY', 'SBC-AAA', 'SBC-AA', 'AGENCY', 'AAA', 'AA'
          I18n.t('dashboard.quick_advance.table.axes_labels.securities_backed')
      end
    end
  end

  def get_type_from_advance_type(advance_type)
    if advance_type
      advance_type = advance_type.upcase.gsub(/\s+/, "")
      case advance_type
        when 'WHOLELOAN', 'WHOLE'
          I18n.t('dashboard.quick_advance.table.whole_loan')
        when 'SBC-AGENCY', 'AGENCY'
          I18n.t('dashboard.quick_advance.table.agency')
        when 'SBC-AAA', 'AAA'
          I18n.t('dashboard.quick_advance.table.aaa')
        when 'SBC-AA', 'AA'
          I18n.t('dashboard.quick_advance.table.aa')
      end
    end
  end

  def check_advance_rate(etransact_service, type, term, old_rate)
    rate_changed = false
    settings = etransact_service.settings
    rate_service = RatesService.new(etransact_service.request)
    rate_details = rate_service.rate(type, term)
    stale_rate = rate_details[:updated_at] + settings[:rate_stale_check].seconds < Time.zone.now if settings && settings[:rate_stale_check]
    if stale_rate
      InternalMailer.stale_rate(settings[:rate_stale_check], rate_service.request_uuid, current_user).deliver_now
    end
    new_rate = rate_details[:rate].to_f
    if new_rate != old_rate.to_f
      rate = new_rate
      rate_changed = true
    else
      rate = old_rate
    end
    {
      advance_rate: rate.to_f,
      old_rate: old_rate.to_f,
      rate_changed: rate_changed,
      stale_rate: stale_rate
    }
  end
  
  def get_collateral_type_from_advance_type(advance_type)
    COLLATERAL_TYPE_MAPPING[advance_type.try(:to_sym)] if advance_type
  end
end