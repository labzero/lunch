class DashboardController < ApplicationController
  include CustomFormattingHelper

  THRESHOLD_CAPACITY = 35 #this will be set by each client, probably with a default value of 35, and be stored in some as-yet-unnamed db
  ADVANCE_TYPES = [:whole, :agency, :aaa, :aa]
  COLLATERAL_ERROR_MAPPING = {
    whole: I18n.t('dashboard.quick_advance.table.mortgage'),
    agency: I18n.t('dashboard.quick_advance.table.agency'),
    aaa: I18n.t('dashboard.quick_advance.table.aaa'),
    aa: I18n.t('dashboard.quick_advance.table.aa'),
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

    @anticipated_activity = [
      [t('dashboard.anticipated_activity.dividend'), 44503, DateTime.new(2014,9,3), t('dashboard.anticipated_activity.estimated')],
      [t('dashboard.anticipated_activity.advance_interest_payment'), -45345, DateTime.new(2014,9,2), ''],
      [t('dashboard.anticipated_activity.stock_purchase'), -37990, DateTime.new(2014,8,12), t('dashboard.anticipated_activity.estimated')],
    ]

    # @account_overview sub-table row format: [title, value, footnote(optional), precision(optional)]
    if !profile
      profile = {
        credit_outstanding: {}
      }
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
      [t('dashboard.your_account.table.remaining.capacity'), profile[:remaining_collateral_borrowing_capacity]],
      [t('dashboard.your_account.table.remaining.leverage'), profile[:stock_leverage], nil, 2]
    ]

    @account_overview = {sta_balance: sta_balance, credit_outstanding: credit_outstanding, remaining: remaining}

    @market_overview = [{
      name: 'Test',
      data: rate_service.overnight_vrc
    }]

    borrowing_capacity = member_balances.borrowing_capacity_summary(today)

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



    @reports_daily = 2
    @reports_weekly = 1
    @reports_monthly = 4
    @reports_quarterly = 2

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
    @contacts = members_service.member_contacts(current_member_id)
    if @contacts && @contacts[:rm] && @contacts[:cam]
      default_image_path = 'placeholder-usericon.svg'
      cam_image_path = "#{@contacts[:cam][:username]}.jpg"
      rm_image_path = "#{@contacts[:rm][:username]}.jpg"
      @contacts[:cam][:image_url] = Rails.application.assets.find_asset(cam_image_path) ? cam_image_path : default_image_path
      @contacts[:rm][:image_url] = Rails.application.assets.find_asset(rm_image_path) ? rm_image_path : default_image_path
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
    check = EtransactAdvancesService.new(request).check_limits(params[:amount].to_f, params[:advance_term])
    if check[:status] == 'pass'
      preview = EtransactAdvancesService.new(request).quick_advance_validate(current_member_id, params[:amount].to_f, params[:advance_type], params[:advance_term], params[:advance_rate].to_f, params[:check_capstock], session['signer_full_name'])
      if preview[:status] && preview[:status].include?('CapitalStockError')
        preview_success = false
        preview_error = false
        @advance_amount = params[:amount].to_f if params[:amount]
        @original_amount = params[:amount].to_f if params[:amount]
        @authorized_amount = preview[:authorized_amount]
        @exception_message = preview[:exception_message]
        @cumulative_stock_required = preview[:cumulative_stock_required]
        @current_trade_stock_required = preview[:current_trade_stock_required]
        @pre_trade_stock_required = preview[:pre_trade_stock_required]
        @net_stock_required = preview[:net_stock_required]
        @gross_amount = preview[:gross_amount]
        @gross_cumulative_stock_required = preview[:gross_cumulative_stock_required]
        @gross_current_trade_stock_required = preview[:gross_current_trade_stock_required]
        @gross_pre_trade_stock_required = preview[:gross_pre_trade_stock_required]
        @gross_net_stock_required = preview[:gross_net_stock_required]
        response_html = render_to_string :quick_advance_capstock, layout: false
      elsif preview[:status] && (preview[:status].include?('GrossUpError') || preview[:status].include?('ExceptionError'))
        preview_success = false
        preview_error = true
        @error_message = check[:status]
        @advance_amount = params[:amount].to_f if params[:amount]
        @advance_description = get_description_from_advance_term(params[:advance_term]) if params[:advance_term]
        @advance_program = get_program_from_advance_type(params[:advance_type]) if params[:advance_type]
        @advance_type = get_type_from_advance_type(params[:advance_type]) if params[:advance_type]
        @advance_term = params[:advance_term].capitalize if params[:advance_term]
        @advance_rate = params[:advance_rate].to_f if params[:advance_rate]
        @interest_day_count = params[:interest_day_count]
        @payment_on = params[:payment_on]
        @maturity_date = params[:maturity_date]
        @funding_date = Time.zone.now.to_date
        response_html = render_to_string :quick_advance_error, layout: false
      elsif preview[:status] && preview[:status].include?('CreditError')
        preview_success = false
        preview_error = true
        @advance_amount = params[:amount].to_f if params[:amount]
        @error_message = 'CreditError'
        @advance_description = get_description_from_advance_term(params[:advance_term]) if params[:advance_term]
        @advance_program = get_program_from_advance_type(params[:advance_type]) if params[:advance_type]
        @advance_type = get_type_from_advance_type(params[:advance_type]) if params[:advance_type]
        @advance_term = params[:advance_term].capitalize if params[:advance_term]
        @advance_rate = params[:advance_rate].to_f if params[:advance_rate]
        @interest_day_count = params[:interest_day_count]
        @payment_on = params[:payment_on]
        @maturity_date = params[:maturity_date]
        @funding_date = Time.zone.now.to_date
        response_html = render_to_string :quick_advance_error, layout: false
      elsif preview[:status] && preview[:status].include?('CollateralError')
        preview_success = false
        preview_error = true
        @advance_amount = params[:amount].to_f if params[:amount]
        @error_message = 'CollateralError'
        @advance_description = get_description_from_advance_term(params[:advance_term]) if params[:advance_term]
        @advance_program = get_program_from_advance_type(params[:advance_type]) if params[:advance_type]
        @collateral_type = COLLATERAL_ERROR_MAPPING[params[:advance_type].to_sym] if params[:advance_type]
        @advance_type = get_type_from_advance_type(params[:advance_type]) if params[:advance_type]
        @advance_term = params[:advance_term].capitalize if params[:advance_term]
        @advance_rate = params[:advance_rate].to_f if params[:advance_rate]
        @interest_day_count = params[:interest_day_count]
        @payment_on = params[:payment_on]
        @maturity_date = params[:maturity_date]
        @funding_date = Time.zone.now.to_date
        response_html = render_to_string :quick_advance_error, layout: false
      else
        preview_success = true
        preview_error = false
        @original_amount = params[:amount].to_f if params[:amount]
        @advance_amount = preview[:advance_amount].to_f if preview[:advance_amount]
        @advance_description = get_description_from_advance_term(preview[:advance_term]) if preview[:advance_term]
        @advance_program = get_program_from_advance_type(preview[:advance_type]) if preview[:advance_type]
        @advance_type = get_type_from_advance_type(preview[:advance_type]) if preview[:advance_type]
        @interest_day_count = preview[:interest_day_count]
        @payment_on = preview[:payment_on]
        @advance_term = preview[:advance_term].capitalize if preview[:advance_term]
        @funding_date = preview[:funding_date]
        @maturity_date = preview[:maturity_date]
        @advance_rate = preview[:advance_rate].to_f if preview[:advance_rate]
        @stock = params[:stock].to_f if params[:stock]
        @session_elevated = session_elevated?
        response_html = render_to_string layout: false
      end
    else
      preview_success = false
      preview_error = true
      @error_message = check[:status]
      @min_amount = check[:low]
      @max_amount = check[:high]
      @advance_amount = params[:amount].to_f if params[:amount]
      @advance_description = get_description_from_advance_term(params[:advance_term]) if params[:advance_term]
      @advance_program = get_program_from_advance_type(params[:advance_type]) if params[:advance_type]
      @advance_type = get_type_from_advance_type(params[:advance_type]) if params[:advance_type]
      @advance_term = params[:advance_term].capitalize if params[:advance_term]
      @advance_rate = params[:advance_rate].to_f if params[:advance_rate]
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
      confirmation = EtransactAdvancesService.new(request).quick_advance_execute(current_member_id, params[:amount].to_f, params[:advance_type], params[:advance_term], params[:advance_rate].to_f, session['signer_full_name'])
      if confirmation
        advance_success = true 

        @initiated_at = confirmation[:initiated_at]
        @advance_amount = confirmation[:advance_amount].to_f if confirmation[:advance_amount]
        @advance_description = get_description_from_advance_term(confirmation[:advance_term]) if confirmation[:advance_term]
        @advance_program = get_program_from_advance_type(confirmation[:advance_type]) if confirmation[:advance_type]
        @advance_type = get_type_from_advance_type(confirmation[:advance_type]) if confirmation[:advance_type]
        @interest_day_count = confirmation[:interest_day_count]
        @payment_on = confirmation[:payment_on]
        @advance_term = confirmation[:advance_term].capitalize if confirmation[:advance_term]
        @trade_date = Time.zone.now.to_date
        @funding_date = confirmation[:funding_date]
        @maturity_date = confirmation[:maturity_date]
        @advance_rate = confirmation[:advance_rate].to_f if confirmation[:advance_rate]
        @advance_number = confirmation[:confirmation_number]
        @stock = params[:stock].to_f if params[:stock]
        response_html = render_to_string layout: false
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
    advance_term = advance_term.upcase
    case advance_term
      when 'OVERNIGHT', 'OPEN'
        I18n.t('dashboard.quick_advance.vrc_title')
      else
        I18n.t('dashboard.quick_advance.frc_title')
    end
  end
  def get_program_from_advance_type(advance_type)
    advance_type = advance_type.upcase.gsub(/\s+/, "")
    case advance_type
      when 'WHOLELOAN', 'WHOLE'
        I18n.t('dashboard.quick_advance.table.axes_labels.standard')
      when 'SBC-AGENCY', 'SBC-AAA', 'SBC-AA', 'AGENCY', 'AAA', 'AA'
        I18n.t('dashboard.quick_advance.table.axes_labels.securities_backed')
    end
  end
  def get_type_from_advance_type(advance_type)
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