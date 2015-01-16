class ReportsController < ApplicationController

  MEMBER_ID = 750 #this is the hard-coded fhlb client id number we're using for the time-being


  def index
    @reports = {
      credit: {
        advances_detail: {
          updated: t('global.daily'),
          available_history: t('global.all')
        },
        historical_advances_detail: {
          updated: t('global.daily'),
          available_history: t('reports.history.months18')
        },
        interest_rate: {
          updated: t('global.daily'),
          available_history: t('reports.history.months12')
        },
        letters_of_credit: {
          updated: t('global.daily'),
          available_history: t('global.all')
        },
        forward_commitments: {
          updated: t('global.daily'),
          available_history: t('global.all')
        },
        parallel_shift: {
          updated: t('global.monthly'),
          available_history: t('global.all')
        }
      },
      collateral: {
        borrowing_capacity: {
          updated: t('global.daily'),
          available_history: t('global.all'),
          route: reports_borrowing_capacity_path
        },
        mcu: {
          updated: t('global.daily'),
          available_history: t('global.all')
        }
      },
      capital_stock: {
        trial_balance: {
          updated: t('global.daily'),
          available_history: t('global.all')
        },
        activity: {
          updated: t('global.daily'),
          available_history: t('reports.history.months12'),
          route: reports_capital_stock_activity_path
        },
        dividend_transaction: {
          updated: t('global.quarterly'),
          available_history: t('reports.history.months36')
        },
        dividend_statement: {
          updated: t('global.quarterly'),
          available_history: t('reports.history.present2007')
        }
      },
      settlement: {
        account: {
          updated: t('global.daily'),
          available_history: t('global.all')
        }
      },
      securities: {
        transactions: {
          updated: t('reports.twice_daily'),
          available_history: t('global.all')
        },
        cash_projections: {
          updated: t('global.daily'),
          available_history: t('global.current_day')
        },
        current: {
          updated: t('reports.continuously'),
          available_history: t('global.current_day')
        },
        monthly: {
          updated: t('global.monthly'),
          available_history: t('reports.history.months18')
        },
        services_monthly: {
          updated: t('global.monthly'),
          available_history: t('reports.history.months18')
        }
      }
    }
  end

  def capital_stock_activity
    member_balances = MemberBalanceService.new(MEMBER_ID)
    this_month_start = Date.today.beginning_of_month
    this_month_end = Date.today
    last_month_start = this_month_start - 1.month
    last_month_end = last_month_start.end_of_month
    @start_date = (params[:start_date] || last_month_start).to_date
    @end_date = (params[:end_date] || last_month_end).to_date
    @capital_stock_activity = member_balances.capital_stock_activity(@start_date.to_date, @end_date.to_date)
    raise StandardError, "There has been an error and ReportsController#capital_stock_activity has returned nil. Check error logs." if @capital_stock_activity.blank?
    @picker_presets = [
      {
        label: t('datepicker.range.this_month', month: this_month_start.strftime('%B')),
        start_date: this_month_start,
        end_date: this_month_end
      },
      {
        label: last_month_start.strftime('%B'),
        start_date: last_month_start,
        end_date: last_month_end
      },
      {
        label: t('datepicker.range.custom'),
        start_date: @start_date,
        end_date: @end_date,
        is_custom: true
      }
    ]
    @picker_presets.each do |preset|
      if preset[:start_date] == @start_date && preset[:end_date] == @end_date
        preset[:is_default] = true
        break
      end
    end
  end

  def borrowing_capacity
    member_balances = MemberBalanceService.new(MEMBER_ID)
    date = params[:end_date] || Date.today
    @borrowing_capacity_summary = member_balances.borrowing_capacity_summary(date.to_date)
    raise StandardError, "There has been an error and ReportsController#borrowing_capacity has returned nil. Check error logs." if @borrowing_capacity_summary.blank?
  end

end