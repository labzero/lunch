module ReportConfiguration
  extend DatePickerHelper

  # this is the name at the top of the report (not in navigation, not a report file name, etc.)
  def self.report_title(report_key)
    case report_key
    when :capital_stock_trial_balance
      I18n.t('reports.pages.capital_stock_trial_balance.title')
    when :borrowing_capacity
      I18n.t('global.borrowing_capacity')
    when :settlement_transaction_account
      I18n.t('reports.pages.settlement_transaction_account.title')
    when :current_price_indications
      I18n.t('reports.pages.price_indications.current.title')
    when :historical_price_indications
      I18n.t('reports.pages.price_indications.historical.title')
    when :securities_services_statement
      I18n.t('reports.securities.services_monthly.title')
    when :letters_of_credit
      I18n.t('reports.pages.letters_of_credit.title')
    when :securities_transactions
      I18n.t('reports.pages.securities_transactions.title')
    when :authorizations
      I18n.t('reports.account.authorizations.title')
    when :current_securities_position
      I18n.t('reports.pages.securities_position.current')
    when :monthly_securities_position
      I18n.t('reports.pages.securities_position.monthly')
    when :forward_commitments
      I18n.t('reports.credit.forward_commitments.title')
    when :account_summary
      I18n.t('reports.pages.account_summary.title')
    when :cash_projections
      I18n.t('reports.pages.cash_projections.title')
    else
      nil
    end
  end

  def self.date_restrictions(report_key)
    case report_key
    when :capital_stock_activity
      12.months
    when :settlement_transaction_account
      6.months
    when :advances_detail, :securities_services_statement, :monthly_securities_position
      18.months
    when :dividend_statement
      36.months
    else
      nil
    end
  end

  # returns { min: a, start: b, end: c, max: d }
  # (a,b,c and d will be a Date object or nil)
  def self.date_bounds(report_key, start_date_param = nil, end_date_param = nil)
    start_date_param = start_date_param.to_date if start_date_param
    end_date_param = end_date_param.to_date if end_date_param
    case report_key
    when :capital_stock_activity
      start_date = (start_date_param || default_dates_hash[:last_month_start]).to_date
      end_date = (end_date_param || default_dates_hash[:last_month_end]).to_date
      min_date, start_date = min_and_start_dates(date_restrictions(:capital_stock_activity), start_date)
      { min: min_date, start: start_date, end: end_date, max: nil }
    when :capital_stock_trial_balance
      min_date = Date.new(2002,1,1)
      max_date = most_recent_business_day(Time.zone.today - 1.day)
      start_date = start_date_param ? [start_date_param.to_date, max_date].min : max_date
      start_date = min_date if start_date < min_date
      { min: min_date, start: start_date, end: nil, max: max_date }
    when :borrowing_capacity
      { min: nil, start: nil, end: end_date_param || Time.zone.now.to_date, max: nil }
    when :settlement_transaction_account
      start_date = (start_date_param || default_dates_hash[:this_month_start]).to_date
      min_date, start_date = min_and_start_dates(date_restrictions(:settlement_transaction_account), start_date)
      end_date = (end_date_param || Time.zone.today).to_date
      { min: min_date, start: start_date, end: end_date, max: nil }
    when :advances_detail
      max_date = most_recent_business_day(Time.zone.today - 1.day)
      advance_start_date = start_date_param ? [start_date_param.to_date, max_date].min : max_date
      min_date, start_date = min_and_start_dates(date_restrictions(:advances_detail), advance_start_date)
      { min: min_date, start: start_date, end: nil, max: max_date }
    when :historical_price_indications
      start_date = (start_date_param || default_dates_hash[:last_30_days]).to_date
      end_date = (end_date_param || default_dates_hash[:today]).to_date
      { min: nil, start: start_date, end: end_date, max: nil }
    when :securities_transactions
      max_date = most_recent_business_day(Time.zone.today)
      start_date = start_date_param ? [start_date_param.to_date, max_date].min : max_date
      { min: nil, start: start_date, end: nil, max: max_date }
    when :monthly_securities_position
      start_date = (start_date_param || last_month_end).to_date
      min_date, start_date = min_and_start_dates(date_restrictions(:monthly_securities_position), start_date)
      end_date = month_restricted_start_date(start_date)
      { min: min_date, start: start_date, end: end_date, max: nil }
    else
      { min: nil, start: nil, end: nil, max: nil }
    end
  end
end