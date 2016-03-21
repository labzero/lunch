require 'rails_helper'

RSpec.describe ReportConfiguration do
  subject { ReportConfiguration }

  let(:capital_stock_activity_restriction) { 12.months }
  let(:settlement_transaction_account_restriction) { 6.months }
  let(:advances_detail_restriction) { 18.months }
  let(:securities_services_statement_restriction) { 18.months }
  let(:monthly_securities_position_restriction) { 18.months }
  let(:dividend_statement_restriction) { 36.months }

  it 'responds to `report_title`' do
    expect(subject).to respond_to(:date_restrictions)
  end

  describe 'the `report_title` method' do
    it 'returns nil if report type not found or supported' do
    [ :cash_projections, :interest_rate_resets, :fake_report_type ]. each do |report_type|
        expect(subject.report_title(report_type)).to eq(nil)
      end
    end

    it 'returns the matching report title for each report type' do
    { capital_stock_trial_balance: I18n.t('reports.pages.capital_stock_trial_balance.title'),
      borrowing_capacity: I18n.t('global.borrowing_capacity'),
      settlement_transaction_account: I18n.t('reports.pages.settlement_transaction_account.title'),
      current_price_indications: I18n.t('reports.pages.price_indications.current.title'),
      historical_price_indications: I18n.t('reports.pages.price_indications.historical.title'),
      securities_services_statement: I18n.t('reports.securities.services_monthly.title'),
      letters_of_credit: I18n.t('reports.pages.letters_of_credit.title'),
      securities_transactions: I18n.t('reports.pages.securities_transactions.title'),
      authorizations: I18n.t('reports.account.authorizations.title'),
      current_securities_position: I18n.t('reports.pages.securities_position.current'),
      monthly_securities_position: I18n.t('reports.pages.securities_position.monthly'),
      forward_commitments: I18n.t('reports.credit.forward_commitments.title'),
      account_summary: I18n.t('reports.pages.account_summary.title') }.each do |report_type, expected_rval|
        expect(subject.report_title(report_type)).to eq(expected_rval)
      end
    end
  end

  it 'responds to `date_restrictions`' do
    expect(subject).to respond_to(:date_restrictions)
  end

  describe 'the `date_restrictions` method' do
    it 'returns nil if report type not found or supported' do
    [ :capital_stock_trial_balance, :borrowing_capacity, :current_price_indications, :historical_price_indications,
      :cash_projections, :interest_rate_resets, :securities_transactions, :authorizations,
      :forward_commitments, :fake_report_type ]. each do |report_type|
        expect(subject.date_restrictions(report_type)).to eq(nil)
      end
    end

    it 'returns matching date restrictions for each report type' do
      { capital_stock_activity: capital_stock_activity_restriction,
        settlement_transaction_account: settlement_transaction_account_restriction,
        advances_detail: advances_detail_restriction,
        securities_services_statement: securities_services_statement_restriction,
        monthly_securities_position: monthly_securities_position_restriction,
        dividend_statement: dividend_statement_restriction }
      .each do |report_type, expected_rval|
        expect(subject.date_restrictions(report_type)).to eq(expected_rval)
      end
    end
  end

  it 'responds to `date_bounds`' do
    expect(subject).to respond_to(:date_bounds)
  end

  describe 'the `date_bounds` method' do
    let(:min_date) { Date.new(2002,1,1) }
    let(:today) { Time.zone.today }
    let(:start_date) { 1.day.ago.to_date }
    let(:end_date) { (start_date + 2.days).to_date }
    let(:max_date) { subject.most_recent_business_day(Time.zone.today - 1.day) }
    let(:this_month_start) { subject.default_dates_hash[:this_month_start] }
    let(:last_month_start) { subject.default_dates_hash[:last_month_start] }
    let(:last_month_end) { subject.default_dates_hash[:last_month_end] }

    it 'returns hash of nils if report type not found or supported' do
    [ :current_price_indications,
      :cash_projections,
      :interest_rate_resets,
      :authorizations,
      :forward_commitments,
      :fake_report_type ]. each do |report_type|
        expect(subject.date_bounds(report_type, DateTime.now, DateTime.now)).to eq(
          { min: nil, start: nil, end: nil, max: nil })
      end
    end

    describe 'when processing the capital stock activity report' do
      let(:min_date) { subject.date_restrictions(:capital_stock_activity).ago.to_date }

      it 'returns correct dates when nil dates supplied' do
        expect(subject.date_bounds(:capital_stock_activity, nil, nil)).to eq(
          { min: min_date, start: last_month_start, end: last_month_end, max: nil })
      end

      it 'returns correct dates when valid dates supplied (happy path)' do
        expect(subject.date_bounds(:capital_stock_activity, start_date, end_date)).to eq(
          { min: min_date, start: start_date, end: end_date, max: nil })
      end

      it 'returns min for start date when start date comes before min date' do
        expect(subject.date_bounds(:capital_stock_activity, start_date - 13.months, end_date)).to eq(
          { min: min_date, start: min_date, end: end_date, max: nil })
      end
    end

    describe 'when processing the capital stock trial balance report' do
      it 'returns max for start date when start date is nil' do
        expect(subject.date_bounds(:capital_stock_trial_balance, nil, nil)).to eq(
          { min: min_date, start: max_date, end: nil, max: max_date })
      end

      it 'returns min date for start date when start date comes before min date' do
        expect(subject.date_bounds(:capital_stock_trial_balance, min_date - 1.day, nil)).to eq(
          { min: min_date, start: min_date, end: nil, max: max_date })
      end

      it 'returns max date for start date when start date comes after max date' do
        expect(subject.date_bounds(:capital_stock_trial_balance, max_date + 1.day, nil)).to eq(
          { min: min_date, start: max_date, end: nil, max: max_date })
      end

      it 'returns supplied start date when start date is in bounds (happy path)' do
        expect(subject.date_bounds(:capital_stock_trial_balance, max_date - 5.day, nil)).to eq(
          { min: min_date, start: max_date - 5.days, end: nil, max: max_date })
      end
    end

    describe 'when processing the borrowing capacity report' do
      it 'returns today for end date when end date is nil' do
        expect(subject.date_bounds(:borrowing_capacity, nil, nil)).to eq(
          { min: nil, start: nil, end: today, max: nil })
      end

      it 'returns min date for start date when start date comes before min date' do
        expect(subject.date_bounds(:capital_stock_trial_balance, min_date - 1.day, nil)).to eq(
          { min: min_date, start: min_date, end: nil, max: max_date })
      end

      it 'returns max date for start date when start date comes after max date' do
        expect(subject.date_bounds(:capital_stock_trial_balance, max_date + 1.day, nil)).to eq(
          { min: min_date, start: max_date, end: nil, max: max_date })
      end
    end

    describe 'when processing the settlement transaction account report' do
      let(:min_date) { subject.date_restrictions(:settlement_transaction_account).ago.to_date }

      it 'returns default min, start and end dates if start and end dates are nil' do
        expect(subject.date_bounds(:settlement_transaction_account, nil, nil)).to eq(
          { min: min_date, start: this_month_start, end: today, max: nil })
      end

      it 'returns min date for start date when start date comes before min date' do
        expect(subject.date_bounds(:settlement_transaction_account, min_date - 1.day, nil)).to eq(
          { min: min_date, start: min_date, end: today, max: nil })
      end

      it 'returns in bounds start and end date if supplied (happy path)' do
        expect(subject.date_bounds(:settlement_transaction_account, today, today + 1.day)).to eq(
          { min: min_date, start: today, end: today + 1.day, max: nil })
      end
    end

    describe 'when processing the advances detail report' do
      let(:min_date) { subject.date_restrictions(:advances_detail).ago.to_date }

      it 'returns the last business day as max date and nil as end date and sets default min and start dates' do
        expect(subject.date_bounds(:advances_detail, nil, nil)).to eq(
          { min: min_date, start: max_date, end: nil, max: max_date })
      end

      it 'returns min date for start date when start date comes before min date' do
        expect(subject.date_bounds(:advances_detail, min_date - 1.day, nil)).to eq(
          { min: min_date, start: min_date, end: nil, max: max_date })
      end

      it 'returns in bounds start date if supplied (happy path)' do
        expect(subject.date_bounds(:advances_detail, min_date + 5.days, nil)).to eq(
          { min: min_date, start: min_date + 5.days, end: nil, max: max_date })
      end
    end

    describe 'when processing the historical price indications report' do
      let(:this_year_start) { subject.default_dates_hash[:this_year_start] }

      it 'defaults start date to 30 days ago and end date to today' do
        expect(subject.date_bounds(:historical_price_indications, nil, nil)).to eq(
          { min: nil, start: subject.default_dates_hash[:last_30_days], end: today, max: nil })
      end

      it 'returns in bounds start and end dates if supplied (happy path)' do
        expect(subject.date_bounds(:historical_price_indications, 6.months.ago.to_date, 3.months.ago.to_date)).to eq(
          { min: nil, start: 6.months.ago.to_date, end: 3.months.ago.to_date, max: nil })
      end
    end

    describe 'when processing the securities transactions report' do
      let(:max_date) { subject.most_recent_business_day(Time.zone.today) }

      it 'defaults start and max to the most recent business day' do
        expect(subject.date_bounds(:securities_transactions, nil, nil)).to eq(
          { min: nil, start: max_date, end: nil, max: max_date })
      end

      it 'returns max for start date when start date comes after max date' do
        expect(subject.date_bounds(:securities_transactions, max_date + 1.day, nil)).to eq(
          { min: nil, start: max_date, end: nil, max: max_date })
      end

      it 'returns in bounds start date if supplied (happy path)' do
        expect(subject.date_bounds(:securities_transactions, 6.months.ago.to_date, nil)).to eq(
          { min: nil, start: 6.months.ago.to_date, end: nil, max: max_date })
      end
    end

    describe 'when processing the monthly securities position report' do
      let(:min_date) { subject.date_restrictions(:monthly_securities_position).ago.to_date }
      let(:start_date) { last_month_end }
      let(:end_date) { subject.month_restricted_start_date(start_date) }
      it 'defaults start date to last month end and end date to month-restricted start' do
        expect(subject.date_bounds(:monthly_securities_position, nil, nil)).to eq(
          { min: min_date, start: start_date, end: end_date, max: nil })
      end

      it 'returns min date for start date when start date comes before min date' do
        expect(subject.date_bounds(:monthly_securities_position, min_date - 1.month, nil)).to eq(
          { min: min_date, start: min_date, end: subject.month_restricted_start_date(min_date), max: nil })
      end
    end
  end
end