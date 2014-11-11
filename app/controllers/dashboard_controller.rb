class DashboardController < ApplicationController

  def index
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
      [t('dashboard.your_account.balance'), 1973179.93],
      [t('dashboard.your_account.credit_outstanding'), 105000000]
    ]

    remaining = [
      [t('dashboard.your_account.remaining.available'), 105000000],
      [t('dashboard.your_account.remaining.leverage'), 12400000]
    ]

    market_value = [
      [t('dashboard.your_account.market_value.agency'), 0],
      [t('dashboard.your_account.market_value.aaa'), 0],
      [t('dashboard.your_account.market_value.aa'), 0]
    ]

    borrowing_capacity = [
      [t('dashboard.your_account.borrowing_capacity.standard'), 65000000],
      [t('dashboard.your_account.borrowing_capacity.agency'), 0],
      [t('dashboard.your_account.borrowing_capacity.aaa'), 0],
      [t('dashboard.your_account.borrowing_capacity.aa'), 0]
    ]

    @sub_tables = {remaining: remaining, market_value: market_value, borrowing_capacity: borrowing_capacity}

  end



end