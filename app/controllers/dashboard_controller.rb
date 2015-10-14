class DashboardController < ApplicationController
  include CustomFormattingHelper
  include DashboardHelper

  THRESHOLD_CAPACITY = 35 #this will be set by each client, probably with a default value of 35, and be stored in some as-yet-unnamed db

  before_action only: [:quick_advance_rates, :quick_advance_preview, :quick_advance_perform] do
    authorize :advances, :show?
  end

  before_action only: [:quick_advance_perform, :quick_advance_preview] do
    advance_request_from_session
  end

  after_action only: [:quick_advance_rates, :quick_advance_perform, :quick_advance_preview] do
    advance_request_to_session
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
      [t('dashboard.your_account.table.remaining.available'), profile[:remaining_financing_available]],
      [t('dashboard.your_account.table.remaining.capacity'), (profile[:collateral_borrowing_capacity] || {})[:remaining]],
      [t('dashboard.your_account.table.remaining.leverage'), (profile[:capital_stock] || {})[:remaining_leverage]]
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
    advance_request_clear!
    @rate_data = advance_request.rates
    @advance_terms = AdvanceRequest::ADVANCE_TERMS
    @advance_types = AdvanceRequest::ADVANCE_TYPES
    render layout: false
  end

  def quick_advance_preview
    @current_member_name = current_member_name
    @preview = true

    advance_request.type = params[:advance_type] if params[:advance_type]
    advance_request.term = params[:advance_term] if params[:advance_term]
    advance_request.amount = params[:amount] if params[:amount]
    advance_request.stock_choice = params[:stock_choice] if params[:stock_choice]

    advance_request.validate_advance
    populate_advance_request_view_parameters

    if advance_request.errors.present?
      limit_error = advance_request.errors.find {|e| e.type == :limits}
      preview_errors = advance_request.errors.select {|e| e.type == :preview }
      rate_error = advance_request.errors.find {|e| e.type == :rate}

      if limit_error.present?
        preview_success = false
        preview_error = true
        @error_message = limit_error.code
        @error_value = limit_error.value
      elsif rate_error.present?
        preview_success = false
        preview_error = true
        @error_message = rate_error.code
      else
        if preview_errors.find {|e| e.code == :capital_stock}
          preview_success = false
          preview_error = false
          @original_amount = advance_request.amount
          response_html = render_to_string :quick_advance_capstock, layout: false
        else
          preview_success = false
          preview_error = true
          [:capital_stock_offline, :credit, :collateral, :total_daily_limit].each do |code|
            error = preview_errors.find {|e| e.code == code}
            if error
              @error_message = code
              @error_value = error.value
              break
            end
          end
        end
      end
    else
      preview_success = true
      preview_error = false
    end

    if preview_error
      response_html = render_to_string :quick_advance_error, layout: false
    elsif !response_html
      @original_amount = @advance_amount.to_f
      @stock = advance_request.sta_debit_amount
      @session_elevated = session_elevated?
      advance_request.timestamp!
      response_html = render_to_string layout: false
    end

    render json: {preview_success: preview_success, preview_error: preview_error, html: response_html}
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
      expired_rate = advance_request.expired?
      if expired_rate
        advance_success = false
        populate_advance_request_view_parameters
        @error_message = :rate_expired
        response_html = render_to_string :quick_advance_error, layout: false
      else
        advance_request.execute
        
        if advance_request.executed?
          advance_success = true
          populate_advance_request_view_parameters
          @stock = advance_request.sta_debit_amount
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

  def populate_advance_request_view_parameters
    @authorized_amount = advance_request.authorized_amount
    @cumulative_stock_required = advance_request.cumulative_stock_required
    @current_trade_stock_required = advance_request.current_trade_stock_required
    @pre_trade_stock_required = advance_request.pre_trade_stock_required
    @net_stock_required = advance_request.net_stock_required
    @gross_amount = advance_request.gross_amount
    @gross_cumulative_stock_required = advance_request.gross_cumulative_stock_required
    @gross_current_trade_stock_required = advance_request.gross_current_trade_stock_required
    @gross_pre_trade_stock_required = advance_request.gross_pre_trade_stock_required
    @gross_net_stock_required = advance_request.gross_net_stock_required
    @advance_amount = advance_request.amount
    @advance_description = advance_request.term_description
    @advance_type_raw = advance_request.type
    @advance_program = advance_request.program_name
    @advance_type = advance_request.human_type
    @interest_day_count = advance_request.interest_day_count
    @payment_on = advance_request.payment_on
    @advance_term = advance_request.term
    @trade_date = advance_request.trade_date
    @funding_date = advance_request.funding_date
    @maturity_date = advance_request.maturity_date
    @advance_rate = advance_request.rate
    @initiated_at = advance_request.initiated_at
    @advance_number = advance_request.confirmation_number
    @collateral_type = advance_request.collateral_type
    @old_rate = advance_request.old_rate
    @rate_changed = advance_request.rate_changed?
  end

  def advance_request_from_session
    request_hash = session[:advance_request]
    @advance_request = if request_hash 
      AdvanceRequest.from_hash(request_hash, request)
    else
      advance_request
    end
  end

  def advance_request_to_session
    session[:advance_request] = @advance_request.serializable_hash if @advance_request
  end

  def advance_request
    @advance_request ||= AdvanceRequest.new(current_member_id, signer_full_name, request)
  end

  def signer_full_name
    session['signer_full_name'] ||= EtransactAdvancesService.new(request).signer_full_name(current_user.username)
  end

  def advance_request_clear!
    session.delete(:advance_request)
    @advance_request = nil
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
end