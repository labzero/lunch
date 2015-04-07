class DashboardController < ApplicationController

  THRESHOLD_CAPACITY = 35 #this will be set by each client, probably with a default value of 35, and be stored in some as-yet-unnamed db
  ADVANCE_TYPES = [:whole, :agency, :aaa, :aa]
  ADVANCE_TERMS = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']

  def index
    rate_service = RatesService.new(request)
    etransact_service = EtransactAdvancesService.new(request)
    member_balances = MemberBalanceService.new(current_member_id, request)

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

    @pledged_collateral = member_balances.pledged_collateral
    @total_securities = member_balances.total_securities
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
  end

  def quick_advance_rates
    etransact_service = EtransactAdvancesService.new(request)
    @quick_advances_active = etransact_service.etransact_active?
    rate_data = RatesService.new(request).quick_advance_rates(current_member_id)
    render partial: 'quick_advance_table_rows', locals: {rate_data: rate_data, advance_terms: ADVANCE_TERMS, advance_types: ADVANCE_TYPES}
  end

  def quick_advance_preview
    preview = RatesService.new(request).quick_advance_preview(current_member_id, params[:amount].to_f, params[:advance_type], params[:advance_term], params[:advance_rate].to_f)
    render partial: 'quick_advance_preview', locals: preview # key names received from RatesService.new.quick_advance_preview must match variable names in partial
  end

  def quick_advance_confirmation
    confirmation = RatesService.new(request).quick_advance_confirmation(current_member_id, params[:amount].to_f, params[:advance_type], params[:advance_term], params[:advance_rate].to_f)
    render json: confirmation # this will likely become a partial once we have designs for the confirmation dialog
  end

  def current_overnight_vrc
    etransact_service = EtransactAdvancesService.new(request)
    response = RatesService.new(request).current_overnight_vrc || {}
    response[:quick_advances_active] = etransact_service.etransact_active?
    render json: response
  end
end