class ReportsController < ApplicationController
  include DatePickerHelper

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
          available_history: t('global.all'),
          route: reports_settlement_transaction_account_path
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
    default_dates = default_dates_hash
    member_balances = MemberBalanceService.new(MEMBER_ID)
    @start_date = ((params[:start_date] || default_dates[:last_month_start])).to_date
    @end_date = ((params[:end_date] || default_dates[:last_month_end])).to_date
    @capital_stock_activity = member_balances.capital_stock_activity(@start_date, @end_date)
    raise StandardError, "There has been an error and ReportsController#capital_stock_activity has returned nil. Check error logs." if @capital_stock_activity.blank?
    @picker_presets = range_picker_default_presets(@start_date, @end_date)
  end

  def borrowing_capacity
    member_balances = MemberBalanceService.new(MEMBER_ID)
    date = params[:end_date] || Date.today
    @borrowing_capacity_summary = member_balances.borrowing_capacity_summary(date.to_date)
    raise StandardError, "There has been an error and ReportsController#borrowing_capacity has returned nil. Check error logs." if @borrowing_capacity_summary.blank?
  end

  def settlement_transaction_account
    default_dates = default_dates_hash
    member_balances = MemberBalanceService.new(MEMBER_ID)
    @start_date = ((params[:start_date] || default_dates[:last_month_start])).to_date
    @end_date = ((params[:end_date] || default_dates[:last_month_end])).to_date
    @daily_balance_key = MemberBalanceService::DAILY_BALANCE_KEY
    @picker_presets = range_picker_default_presets(@start_date, @end_date)
    @filter_options = [
        [t('global.all'), 'all'],
        [t('global.debits'), 'debit'],
        [t('global.credits'), 'credit']
    ]
    filter_param = params[:sta_filter]
    @filter_options.each do |option|
      if option[1] == filter_param
        @filter = filter_param
        @filter_text = option[0]
      end
    end
    # default filter to 'all' if invalid filter param was passed
    @filter ||= @filter_options[0][1]
    @filter_text ||= @filter_options[0][0]
    @settlement_transaction_account = member_balances.settlement_transaction_account(@start_date, @end_date, @filter)
    @show_ending_balance = false
    if @settlement_transaction_account[:activities] && @settlement_transaction_account[:activities].length > 0
      @show_ending_balance = @end_date != @settlement_transaction_account[:activities][0][:trans_date].to_date || @settlement_transaction_account[:activities][0][:balance].blank?
    end
    raise StandardError, "There has been an error and ReportsController#settlement_transaction_account has returned nil. Check error logs." if @settlement_transaction_account.blank?
  end

end