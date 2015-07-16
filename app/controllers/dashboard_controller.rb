class DashboardController < ApplicationController

  THRESHOLD_CAPACITY = 35 #this will be set by each client, probably with a default value of 35, and be stored in some as-yet-unnamed db
  ADVANCE_TYPES = [:whole, :agency, :aaa, :aa]
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
      nil
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
      nil
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

    @quick_advance_enabled= members_service.quick_advance_enabled_for_member?(current_member_id)
    @quick_advances_active = etransact_service.etransact_active?
    # TODO replace this with the timestamp from the cached quick advance rates timestamp
    date = DateTime.now - 2.hours
    @quick_advance_last_updated = date.strftime("%d %^b %Y, %l:%M %p")
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
    preview = EtransactAdvancesService.new(request).quick_advance_validate(current_member_id, params[:amount].to_f, params[:advance_type], params[:advance_term], params[:advance_rate].to_f, params[:check_capstock], session['signer_full_name'])
    case preview[:status]
    when 'CapitalStockError'
      preview_success = false
      preview_error = false
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
      @gross_net_stock_required = preview[:net_stock_required]
      response_html = render_to_string :quick_advance_capstock, layout: false
    when 'GrossUpError', 'ExceptionError'
      preview_success = false
      preview_error = true
      @advance_amount = params[:amount].to_f
      @advance_type = params[:advance_type]
      @advance_term = params[:advance_term]
      @advance_rate = params[:advance_rate].to_f
      response_html = render_to_string :quick_advance_error, layout: false
    else
      preview_success = true
      preview_error = false
      @advance_amount = preview[:advance_amount]
      @advance_type = preview[:advance_type]
      @interest_day_count = preview[:interest_day_count]
      @payment_on = preview[:payment_on]
      @advance_term = preview[:advance_term]
      @funding_date = preview[:funding_date]
      @maturity_date = preview[:maturity_date]
      @advance_rate = preview[:advance_rate]
      @session_elevated = session_elevated?
      response_html = render_to_string layout: false
    end
    render json: {preview_success: preview_success, preview_error: preview_error, html: response_html, authorized_amount: @authorized_amount, gross_amount: @gross_amount}
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
        @advance_amount = confirmation[:advance_amount]
        @advance_type = confirmation[:advance_type]
        @interest_day_count = confirmation[:interest_day_count]
        @payment_on = confirmation[:payment_on]
        @advance_term = confirmation[:advance_term]
        @funding_date = confirmation[:funding_date]
        @maturity_date = confirmation[:maturity_date]
        @advance_rate = confirmation[:advance_rate]
        @advance_number = confirmation[:confirmation_number]
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

  def calculate_gauge_percentages(gauge_hash, total, excluded_keys)
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