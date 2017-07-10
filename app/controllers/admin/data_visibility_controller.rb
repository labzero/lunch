class Admin::DataVisibilityController < Admin::BaseController
  DATA_VISIBILITY_MAPPING = {
    account_summary: {
      flags: ReportsController::ACCOUNT_SUMMARY_WEB_FLAGS,
      title: I18n.t('reports.account.account_summary.title')
    },
    authorizations: {
      flags: ReportsController::AUTHORIZATIONS_WEB_FLAGS,
      title: I18n.t('reports.account.authorizations.title')
    },
    settlement_transaction_account: {
      flags: ReportsController::SETTLEMENT_TRANSACTION_ACCOUNT_WEB_FLAGS,
      title: I18n.t('reports.account.settlement_transaction_account.title')
    },
    investments: {
      flags: ReportsController::INVESTMENTS_WEB_FLAGS,
      title: I18n.t('reports.account.investments.title')
    },
    cap_stock_activity: {
      flags: ReportsController::CAPITAL_STOCK_ACTIVITY_WEB_FLAGS,
      title: I18n.t('reports.capital_stock.activity.title')
    },
    cap_stock_trial_balance: {
      flags: ReportsController::CAPITAL_STOCK_TRIAL_BALANCE_WEB_FLAGS,
      title: I18n.t('reports.capital_stock.trial_balance.title')
    },
    cap_stock_leverage: {
      flags: ReportsController::CAPITAL_STOCK_AND_LEVERAGE_WEB_FLAGS,
      title: I18n.t('reports.capital_stock.capital_stock_and_leverage.title')
    },
    dividend_statement: {
      flags: ReportsController::DIVIDEND_STATEMENT_WEB_FLAGS,
      title: I18n.t('reports.capital_stock.dividend_statement.title')
    },
    current_price_indications: {
      flags: ReportsController::CURRENT_PRICE_INDICATIONS_WEB_FLAGS,
      title: I18n.t('reports.price_indications.current.title')
    },
    historical_price_indications: {
      flags: ReportsController::HISTORICAL_PRICE_INDICATIONS_WEB_FLAGS,
      title: I18n.t('reports.price_indications.historical.title')
    },
    borrowing_capacity: {
      flags: ReportsController::BORROWING_CAPACITY_WEB_FLAGS,
      title: I18n.t('reports.collateral.borrowing_capacity.title')
    },
    mortgage_collateral_update: {
      flags: ReportsController:: MORTGAGE_COLLATERAL_UPDATE_WEB_FLAGS,
      title: I18n.t('reports.collateral.mcu.title')
    },
    todays_credit: {
      flags: ReportsController::TODAYS_CREDIT_ACTIVITY_WEB_FLAGS,
      title: I18n.t('reports.credit.todays_credit.title')
    },
    advances: {
      flags: ReportsController::ADVANCES_DETAIL_WEB_FLAGS,
      title: I18n.t('reports.credit.advances_detail.title')
    },
    interest_rate: {
      flags: ReportsController::INTEREST_RATE_RESETS_WEB_FLAGS,
      title: I18n.t('reports.credit.interest_rate.title')
    },
    letters_of_credit: {
      flags: ReportsController::LETTERS_OF_CREDIT_WEB_FLAGS,
      title: I18n.t('reports.credit.letters_of_credit.title')
    },
    forward_commitments: {
      flags: ReportsController::FORWARD_COMMITMENTS_WEB_FLAGS,
      title: I18n.t('reports.credit.forward_commitments.title')
    },
    parallel_shift: {
      flags: ReportsController::PARALLEL_SHIFT_WEB_FLAGS,
      title: I18n.t('reports.credit.parallel_shift.title')
    },
    securities_transactions: {
      flags: ReportsController::SECURITIES_TRANSACTION_WEB_FLAGS,
      title: I18n.t('reports.securities.transactions.title')
    },
    cash_projections: {
      flags: ReportsController::CASH_PROJECTIONS_WEB_FLAGS,
      title: I18n.t('reports.securities.cash_projections.title')
    },
    current_securities_position: {
      flags: ReportsController::CURRENT_SECURITIES_POSITION_WEB_FLAG,
      title: I18n.t('reports.securities.current.title')
    },
    monthly_securities_position: {
      flags: ReportsController::MONTHLY_SECURITIES_WEB_FLAGS,
      title: I18n.t('reports.securities.monthly.title')
    },
    securities_services: {
      flags: ReportsController::SECURITIES_SERVICES_STATMENT_WEB_FLAGS,
      title: I18n.t('reports.securities.services_monthly.title')
    }
  }

  before_action do
    set_active_nav(:data_visibility)
    @can_edit_data_visibility = policy(:web_admin).edit_data_visibility?
  end

  def view_flags
    # TODO: look for a member id parameter as part of MEM-2455. If found, look for member-specific flags. Otherwise, fetch global flags
    members_service = MembersService.new(request)
    disabled_ids = members_service.global_disabled_reports
    members = members_service.all_members
    raise 'There has been an error and Admin::DataVisibilityController#view_flags has encountered nil. Check error logs.' if disabled_ids.nil? || members.nil?
    @account_table = data_visibility_table(disabled_ids, [:account_summary, :authorizations, :settlement_transaction_account, :investments])
    @capital_stock_table = data_visibility_table(disabled_ids, [:cap_stock_activity, :cap_stock_trial_balance, :cap_stock_leverage, :dividend_statement])
    @price_indications_table = data_visibility_table(disabled_ids, [:current_price_indications, :historical_price_indications])
    @collateral_table = data_visibility_table(disabled_ids, [:borrowing_capacity, :mortgage_collateral_update])
    @credit_table = data_visibility_table(disabled_ids, [:todays_credit, :advances, :interest_rate, :letters_of_credit, :forward_commitments, :parallel_shift])
    @securities_table = data_visibility_table(disabled_ids, [:securities_transactions, :cash_projections, :current_securities_position, :monthly_securities_position, :securities_services])

    @member_dropdown = {
      default_value: 'all',
      options: [
        [ t('admin.data_visibility.all_members'), 'all' ]
      ]
    }
    members.each do |member|
      @member_dropdown[:options] << [member[:name], member[:id]]
    end
  end

  private

  def data_visibility_table(flags, report_names)
    rows = []
    report_names.each do |report_name|
      data_source_enabled = (flags & DATA_VISIBILITY_MAPPING[report_name][:flags]).empty?
      rows << {
        columns: [
          { name: "data_visibility_flags[#{report_name}]",
            checked: data_source_enabled,
            type: :checkbox,
            label: true,
            submit_unchecked_boxes: true,
            disabled: true #TODO: change to !@can_edit_trade_rules as part of MEM-2455
          },
          {value: DATA_VISIBILITY_MAPPING[report_name][:title]}
        ]
      }
      rows.last[:row_class] = 'data-source-disabled' unless data_source_enabled
    end
    {rows: rows}
  end
end