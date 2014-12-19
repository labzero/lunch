class ReportsController < ApplicationController

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
          available_history: t('global.all')
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
          available_history: t('reports.history.months12')
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

end