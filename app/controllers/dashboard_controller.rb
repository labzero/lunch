class DashboardController < ApplicationController

  THRESHOLD_CAPACITY = 35 #this will be set by each client, probably with a default value of 35, and be stored in some as-yet-unnamed db
  ADVANCE_TYPES = [:whole, :agency, :aaa, :aa]
  ADVANCE_TERMS = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']

  before_action only: [:quick_advance_rates, :quick_advance_preview, :quick_advance_perform] do
    authorize :advances, :show?
  end

  def index
    rate_service = RatesService.new(request)
    etransact_service = EtransactAdvancesService.new(request)
    member_balances = MemberBalanceService.new(current_member_id, request)
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
      [t('dashboard.your_account.table.credit_outstanding'), profile[:credit_outstanding]]
    ]

    remaining = [
      {title: t('dashboard.your_account.table.remaining.title')},
      [t('dashboard.your_account.table.remaining.available'), profile[:financial_available]],
      [t('dashboard.your_account.table.remaining.capacity'), profile[:remaining_collateral_borrowing_capacity]],
      [t('dashboard.your_account.table.remaining.leverage'), profile[:stock_leverage], nil, 2]
    ]

    standard_program = [
      {title: t('dashboard.your_account.table.standard_program.title')},
      [t('dashboard.your_account.table.total_borrowing_capacity'), profile[:standard_total_borrowing_capacity]],
      [t('dashboard.your_account.table.remaining_borrowing_capacity'), profile[:standard_remaining_borrowing_capacity]]
    ]

    sbc_program = [
        {title: t('dashboard.your_account.table.sbc_program.title')},
        [t('dashboard.your_account.table.total_borrowing_capacity'), profile[:sbc_total_borrowing_capacity]],
        [t('dashboard.your_account.table.remaining_borrowing_capacity'), profile[:sbc_remaining_borrowing_capacity]]
    ]

    @account_overview = {sta_balance: sta_balance, credit_outstanding: credit_outstanding, remaining: remaining, standard_program: standard_program, sbc_program: sbc_program}

    @market_overview = [{
      name: 'Test',
      data: rate_service.overnight_vrc
    }]

    @effective_borrowing_capacity = member_balances.effective_borrowing_capacity
    @effective_borrowing_capacity.merge!({threshold_capacity: THRESHOLD_CAPACITY}) if @effective_borrowing_capacity # we'll be pulling threshold capacity from a different source than the MemberBalanceService
    @total_maturing_today = 46500000

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

    @quick_advances_active = etransact_service.etransact_active?
    # TODO replace this with the timestamp from the cached quick advance rates timestamp
    date = DateTime.now - 2.hours
    @quick_advance_last_updated = date.strftime("%d %^b %Y, %l:%M %p")

    @financing_availability = {
      used: {absolute: profile[:used_financing_availability], percentage: profile[:used_financing_availability].fdiv(profile[:financial_available])*100},
      unused: {absolute: profile[:remaining_borrowing_capacity], percentage: profile[:remaining_borrowing_capacity].fdiv(profile[:financial_available])*100},
      uncollateralized: {absolute: profile[:uncollateralized_financing_availability], percentage: profile[:uncollateralized_financing_availability].fdiv(profile[:financial_available])*100}
    }
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
    preview = RatesService.new(request).quick_advance_preview(current_member_id, params[:amount].to_f, params[:advance_type], params[:advance_term], params[:advance_rate].to_f)
    @advance_amount = preview[:advance_amount]
    @advance_type = preview[:advance_type]
    @interest_day_count = preview[:interest_day_count]
    @payment_on = preview[:payment_on]
    @advance_term = preview[:advance_term]
    @funding_date = preview[:funding_date]
    @maturity_date = preview[:maturity_date]
    @advance_rate = preview[:advance_rate]
    @session_elevated = session_elevated?
    render layout: false
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
      confirmation = RatesService.new(request).quick_advance_confirmation(current_member_id, params[:amount].to_f, params[:advance_type], params[:advance_term], params[:advance_rate].to_f)
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
        @advance_number = confirmation[:advance_number]
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
end