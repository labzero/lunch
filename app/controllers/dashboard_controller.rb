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
      data: [
        [DateTime.new(2014, 2, 10), 0.11],
        [DateTime.new(2014, 2, 11), 0.12],
        [DateTime.new(2014, 2, 12), 0.11],
        [DateTime.new(2014, 2, 13), 0.12],
        [DateTime.new(2014, 2, 14), 0.11],
        [DateTime.new(2014, 2, 18), 0.11],
        [DateTime.new(2014, 2, 19), 0.11],
        [DateTime.new(2014, 2, 20), 0.11],
        [DateTime.new(2014, 2, 21), 0.11],
        [DateTime.new(2014, 2, 24), 0.12],
        [DateTime.new(2014, 2, 25), 0.12],
        [DateTime.new(2014, 2, 26), 0.12],
        [DateTime.new(2014, 2, 27), 0.12],
        [DateTime.new(2014, 2, 28), 0.12],
        [DateTime.new(2014, 3, 3), 0.12],
        [DateTime.new(2014, 3, 4), 0.12],
        [DateTime.new(2014, 3, 5), 0.12],
        [DateTime.new(2014, 3, 6), 0.12],
        [DateTime.new(2014, 3, 7), 0.13],
        [DateTime.new(2014, 3, 10), 0.13],
        [DateTime.new(2014, 3, 11), 0.12],
        [DateTime.new(2014, 3, 12), 0.12],
        [DateTime.new(2014, 3, 13), 0.12],
        [DateTime.new(2014, 3, 14), 0.12],
        [DateTime.new(2014, 3, 17), 0.13],
        [DateTime.new(2014, 3, 18), 0.13],
        [DateTime.new(2014, 3, 19), 0.13],
        [DateTime.new(2014, 3, 20), 0.13],
        [DateTime.new(2014, 3, 21), 0.13],
        [DateTime.new(2014, 4, 17), 0.08]]
    }];

  end



end