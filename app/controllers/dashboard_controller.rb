class DashboardController < ApplicationController

  MEMBER_ID = 750 #this is the hard-coded fhlb client id number we're using for the time-being
  THRESHOLD_CAPACITY = 35 #this will be set by each client, probably with a default value of 35, and be stored in some as-yet-unnamed db
  ADVANCE_TYPES = [:whole, :agency, :aaa, :aa]
  ADVANCE_TERMS = [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']

  def index
    rate_service = RatesService.new
    etransact_service = EtransactAdvancesService.new

    @previous_activity = [
      [t('dashboard.previous_activity.overnight_vrc'), 44503000, DateTime.new(2014,9,3)],
      [t('dashboard.previous_activity.overnight_vrc'), 39097000, DateTime.new(2014,9,2)],
      [t('dashboard.previous_activity.overnight_vrc'), 37990040, DateTime.new(2014,8,12)],
      [t('dashboard.previous_activity.overnight_vrc'), 39282021, DateTime.new(2014,2,14)]
    ]

    @anticipated_activity = [
      [t('dashboard.anticipated_activity.dividend'), 44503, DateTime.new(2014,9,3), t('dashboard.anticipated_activity.estimated')],
      [t('dashboard.anticipated_activity.collateral_rebalancing'), nil, DateTime.new(2014,9,2), ''],
      [t('dashboard.anticipated_activity.stock_purchase'), -37990, DateTime.new(2014,8,12), t('dashboard.anticipated_activity.estimated')],
    ]

    @account_overview = [
      [t('dashboard.your_account.table.balance'), 1973179.93],
      [t('dashboard.your_account.table.credit_outstanding'), 105000000]
    ]

    remaining = [
      [t('dashboard.your_account.table.remaining.available'), 105000000],
      [t('dashboard.your_account.table.remaining.leverage'), 12400000]
    ]

    market_value = [
      [t('dashboard.your_account.table.market_value.agency'), 0],
      [t('dashboard.your_account.table.market_value.aaa'), 0],
      [t('dashboard.your_account.table.market_value.aa'), 0]
    ]

    borrowing_capacity = [
      [t('dashboard.your_account.table.borrowing_capacity.standard'), 65000000],
      [t('dashboard.your_account.table.borrowing_capacity.agency'), 0],
      [t('dashboard.your_account.table.borrowing_capacity.aaa'), 0],
      [t('dashboard.your_account.table.borrowing_capacity.aa'), 0]
    ]

    @sub_tables = {remaining: remaining, market_value: market_value, borrowing_capacity: borrowing_capacity}

    @market_overview = [{
      name: 'Test',
      data: rate_service.overnight_vrc
    }];


    member_balances = MemberBalanceService.new(MEMBER_ID)


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
    etransact_service = EtransactAdvancesService.new
    @quick_advances_active = etransact_service.etransact_active?
    rate_data = RatesService.new.quick_advance_rates(MEMBER_ID)
    render partial: 'quick_advance_table_rows', locals: {rate_data: rate_data, advance_terms: ADVANCE_TERMS, advance_types: ADVANCE_TYPES}
  end

  def quick_advance_preview
    rate_data = JSON.parse(params[:rate_data]).with_indifferent_access
    advance_type = rate_data[:advance_type]
    advance_term = rate_data[:advance_term]
    advance_rate = rate_data[:advance_rate].to_f
    preview = RatesService.new.quick_advance_preview(MEMBER_ID, advance_type, advance_term, advance_rate)
    render partial: 'quick_advance_preview', locals: preview # key names received from RatesService.new.quick_advance_preview must match variable names in partial
  end

  def quick_advance_confirmation
    rate_data = JSON.parse(params[:rate_data]).with_indifferent_access
    advance_type = rate_data[:advance_type]
    advance_term = rate_data[:advance_term]
    advance_rate = rate_data[:advance_rate].to_f
    confirmation = RatesService.new.quick_advance_confirmation(MEMBER_ID, advance_type, advance_term, advance_rate)
    render json: confirmation # this will likely become a partial once we have designs for the confirmation dialog
  end

  def current_overnight_vrc
    etransact_service = EtransactAdvancesService.new
    response = RatesService.new.current_overnight_vrc
    response[:quick_advances_active] = etransact_service.etransact_active?
    render json: response
  end
end