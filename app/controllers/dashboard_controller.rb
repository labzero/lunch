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
      data: RatesService.new.overnight_vrc
    }];

    # this info will likely be coming from the model layer, which will query the CDB.  Just throwing fake data in here for now
    # pledged collateral data
    mortgages = 67574000 #probably be something like "mortgages = user.pledged_collateral.mortgages"
    agency = 3000000
    aaa = 15000000
    aa = 5000000
    total_collateral = mortgages + agency + aaa + aa

    # total securities data
    pledged_securities = 40
    safekept_securities = 124
    total_securities = pledged_securities + safekept_securities

    # effective borrowing capacity
    used_capacity = 18800000
    unused_capacity = 105000000
    total_capacity = used_capacity + unused_capacity
    threshold_capacity = 35

    @pledged_collateral = {
        mortgages: {absolute: mortgages, percentage: mortgages.fdiv(total_collateral)*100},
        agency: {absolute: agency, percentage: agency.fdiv(total_collateral)*100},
        aaa: {absolute: aaa, percentage: aaa.fdiv(total_collateral)*100},
        aa: {absolute: aa, percentage: aa.fdiv(total_collateral)*100}
    }

    @total_securities = {
        pledged_securities: {absolute: pledged_securities, percentage: pledged_securities.fdiv(total_securities)*100},
        safekept_securities: {absolute: safekept_securities, percentage: safekept_securities.fdiv(total_securities)*100}
    }

    @effective_borrowing_capacity = {
        used_capacity: {absolute: used_capacity, percentage: used_capacity.fdiv(total_capacity)*100},
        unused_capacity: {absolute: unused_capacity, percentage: unused_capacity.fdiv(total_capacity)*100},
        threshold_capacity: threshold_capacity
    }

  end



end