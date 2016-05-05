include DatePickerHelper

Then(/^I should see "(.*?)" as the report page's main title$/) do |title|
  page.assert_selector('h1', text: title)
end

Then(/^I should see a table of "(.*?)" reports$/) do |title|
  page.assert_selector('.reports-table th', text: title)
end

Given(/^I am on the reports summary page$/) do
  visit "/reports"
end

When(/^I select "(.*?)" from the reports dropdown$/) do |report|
  step 'I don\'t see the reports dropdown'
  step 'I hover on the reports link in the header'
  page.find('.nav-dropdown').click_link(report)
end

Then(/^I should see a preliminary securities transaction report$/) do
  target = I18n.t('reports.pages.securities_transactions.preliminary', date: '')
  page.assert_selector('h2.report-table-title', text:/#{Regexp.quote(target)}/, visible: true)
end

Then(/^I should see "([^"]*)" in the reports dropdown$/) do |report|
  page.find('.nav-dropdown li', text: /\A#{Regexp.quote(report)}\z/)
end

When(/^the "(.*?)" report has no data$/) do |report|
  # placeholder step for now in case we implement turning off data for certain reports during testing
end

When(/^the "(.*?)" table has no data$/) do |report|
  # placeholder step for now in case we implement turning off data for certain sections of reports during testing
end

When(/^the "(.*?)" report has been disabled$/) do |report|
  # placeholder step for now in case we implement disabling reports during testing
end

Then(/^I should see report summary data$/) do
  page.assert_selector('.report-summary-data', visible: true)
end

Then(/^I should see an empty report table with Data Unavailable messaging$/) do
  page.assert_selector('.report-table tbody tr:first-child .dataTables_empty', text: I18n.t('errors.table_data_unavailable'))
end

Then(/^I should see an empty report table with No Records messaging$/) do
  page.assert_selector('.report-table tbody tr:first-child .dataTables_empty', text: I18n.t('errors.table_data_no_records'))
end

Then(/^I should see a report table with multiple data rows$/) do
  page.assert_selector('.report-table tbody tr')
end

Then(/^I should see (\d+) report tables with multiple data rows$/) do |count|
  page.assert_selector('.report-table', count: count)
  page.all('.report-table').each do |table|
    table.assert_selector('tbody tr')
  end
end

Then(/^I should see (\d+) report tables$/) do |count|
  page.assert_selector('.report-table', count: count)
end

Then(/^I should see a loading report table$/) do
  page.assert_selector('.report-table.table-loading', visible: true)
end

When(/^I wait for the report to load$/) do
  page.assert_no_selector('.report-table.table-loading', wait: 180)
  page.assert_no_selector('.report-table.table-error')
end

Then(/^I should see a report header(?: with just (freshness|availability))?$/) do |expected_details|
  page.assert_selector('.report-header .report-details h2', visible: true, exact: true, text: current_member_name)

  freshness_selector = '.report-header .report-details .report-details-freshness'
  availability_selector = '.report-header .report-details .report-details-availability'

  case expected_details
  when 'freshness'
    page.assert_selector(freshness_selector, visible: true)
    page.assert_no_selector(availability_selector)
  when 'availability'
    page.assert_selector(availability_selector, visible: true)
    page.assert_no_selector(freshness_selector)
  when nil
    page.assert_selector(freshness_selector, visible: true)
    page.assert_selector(availability_selector, visible: true)
  end
end


Given(/^I am on the "(.*?)" report page$/) do |report|
  sleep_if_close_to_midnight
  @today = Time.zone.today
  case report
  when 'Account Summary'
    visit '/reports/account-summary'
  when 'Advances Detail'
    visit '/reports/advances'
  when 'Authorizations'
    visit '/reports/authorizations'
  when 'Borrowing Capacity Statement'
    visit '/reports/borrowing-capacity'
  when 'Capital Stock Activity Statement'
    visit '/reports/capital-stock-activity'
  when 'Capital Stock Trial Balance'
    visit '/reports/capital-stock-trial-balance'
  when 'Cash Projections'
    visit '/reports/cash-projections'
  when 'Current Price Indications'
    visit '/reports/current-price-indications'
  when 'Current Securities Position'
    visit '/reports/current-securities-position'
  when 'Capital Stock Position and Leverage Statement'
    visit '/reports/capital-stock-and-leverage'
  when 'Dividend Transaction Statement'
    visit '/reports/dividend-statement'
  when 'Forward Commitments'
    visit '/reports/forward-commitments'
  when 'Historical Price Indications'
    visit '/reports/historical-price-indications'
  when 'Interest Rate Resets'
    visit '/reports/interest-rate-resets'
  when 'Letters of Credit'
    visit '/reports/letters-of-credit'
  when 'Monthly Securities Position'
    visit '/reports/monthly-securities-position'
  when 'Mortgage Collateral Update'
    visit '/reports/mortgage-collateral-update'
  when 'Profile'
    visit '/reports/profile'
  when 'Securities Services Monthly Statement'
    visit '/reports/securities-services-statement'
  when 'Securities Transactions'
    visit '/reports/securities-transactions'
  when 'Settlement Transaction Account Statement'
    visit '/reports/settlement-transaction-account'
  when 'Today\'s Credit'
    visit '/reports/todays-credit'
  else
    raise Capybara::ExpectationNotMet, 'unknown report passed as argument'
  end
  step 'I wait for the report to load'
end

When(/^I click the "(.*?)" column heading$/) do |column_heading|
  heading = case column_heading
    when 'Certificate Sequence'
      I18n.t('reports.pages.capital_stock_activity.certificate_sequence')
    when 'Trade Date'
      I18n.t('common_table_headings.trade_date')
    when 'Date'
      I18n.t('global.date')
    when 'Issue Date'
      I18n.t('global.issue_date')
    when 'Start Date'
      I18n.t('global.start_date')
    when 'End Date'
      I18n.t('global.end_date')
    when 'Dividend'
      I18n.t('reports.pages.dividend_statement.headers.dividend')
    when 'Shares Outstanding'
      I18n.t('global.shares_outstanding')
    when 'Average Shares Outstanding'
      I18n.t('reports.pages.dividend_statement.headers.average_shares')
    when 'Days Outstanding'
      I18n.t('reports.pages.dividend_statement.headers.days_outstanding')
    when 'Settlement Date'
      I18n.t('common_table_headings.settlement_date')
    when 'Outstanding Shares'
      I18n.t('reports.pages.capital_stock_activity.shares_outstanding')
    when 'Maturity Date'
      I18n.t('common_table_headings.maturity_date')
    when 'Funding Date'
      I18n.t('common_table_headings.funding_date')
    else
      raise Capybara::ExpectationNotMet, 'unknown column heading passed as argument'
  end
  page.find('.report-table th', text: /^#{Regexp.quote(heading)}$/).click
end

Then(/^I should see a "(.*?)" for the current month to date$/) do |report_type|
  start_date = @today.beginning_of_month.strftime('%B %-d, %Y')
  end_date = @today.strftime('%B %-d, %Y')
  step %{I should see a "#{report_type}" starting on "#{start_date}" and ending on "#{end_date}"}
end

Then(/^I should see a "(.*?)" for the last month$/) do |report_type|
  last_month = (@today.beginning_of_month - 1.months)
  start_date = last_month.strftime('%B %-d, %Y')
  end_date = last_month.end_of_month.strftime('%B %-d, %Y')
  step %{I should see a "#{report_type}" starting on "#{start_date}" and ending on "#{end_date}"}
end

Then(/^I should see a "([^"]*)" for the (\d+)(?:st|rd|th) of the last month$/) do |report, day|
  start_date = (Date.new(@today.year, @today.month, day.to_i) - 1.month)
  case report
  when 'Securities Services Monthly Statement'
    heading = /^#{Regexp.quote(report_summary_with_date('reports.pages.securities_services_statement.heading', fhlb_date_long_alpha(start_date)))}$/
    sentinel = 'XXXXXXXXXX'
    footer_base = report_summary_with_date('reports.pages.securities_services_statement.footer', fhlb_date_long_alpha(start_date), {account_number: sentinel})
    footer = /^#{Regexp.quote(footer_base).gsub(sentinel, '\d+')}$/
  else
    raise 'unknown report'
  end

  expect(page.find(".datepicker-trigger input").value).to eq(I18n.t('datepicker.single.input', date: fhlb_date_standard_numeric(start_date)))
  page.assert_selector('.report-summary-data h3', text: strip_tags(heading)) if heading
  page.assert_selector('.report-summary-data h3', text: strip_tags(footer)) if footer
end

Then(/^I should see a "(.*?)" for the (\d+)(?:st|rd|th) through the (\d+)(?:st|rd|th) of (this|last) month$/) do |report_type, start_day, end_day, month|
  month_date = case month
    when 'this'
      @today
    when 'last'
      (@today - 1.month)
    else
      raise 'Month not recognized'
  end
  start_date = Date.new(month_date.year, month_date.month, start_day.to_i).strftime('%B %-d, %Y')
  end_date = Date.new(month_date.year, month_date.month, end_day.to_i).strftime('%B %-d, %Y')
  step %{I should see a "#{report_type}" starting on "#{start_date}" and ending on "#{end_date}"}
end

Then(/^I should see a "(.*?)" starting on "(.*?)" and ending on "(.*?)"$/) do |report_type, start_date, end_date|
  start_date_obj = start_date.to_date
  end_date_obj = end_date.to_date
  case report_type
    when "Settlement Transaction Account Statement"
      opening_balance = report_summary_with_date('reports.pages.settlement_transaction_account.opening_balance_heading', start_date_obj.strftime('%B %-d, %Y'))
      closing_balance = report_summary_with_date('reports.pages.settlement_transaction_account.closing_balance_heading', end_date_obj.strftime('%B %-d, %Y'))
    when "Capital Stock Activity Statement"
      opening_balance = report_summary_with_date('reports.pages.capital_stock_activity.opening_balance_heading', start_date_obj.strftime('%B %-d, %Y'))
      closing_balance = report_summary_with_date('reports.pages.capital_stock_activity.closing_balance_heading', end_date_obj.strftime('%B %-d, %Y'))
    else raise "unknown report type"
  end
  expect(page.find(".datepicker-trigger input").value).to eq("#{start_date_obj.strftime('%m/%d/%Y')} - #{end_date_obj.strftime('%m/%d/%Y')}")
  step %{I should see "#{strip_tags(opening_balance)}"}
  step %{I should see "#{strip_tags(closing_balance)}"}
  report_dates_in_range?(start_date_obj, end_date_obj)
end

Then(/^I should see a "(.*?)" starting (\d+) months? ago and ending today$/) do |report_type, month|
  month = month.to_i
  start_date = month.months.ago
  step %{I should see a "#{report_type}" starting on "#{start_date}" and ending on "#{@today}"}
end

Then(/^I should see a "(.*?)" report as of (\d+) months? ago$/) do |report_type, month|
  end_of_month_reports = ['Securities Services Monthly Statement', 'Monthly Securities Position']
  month = month.to_i
  as_of_date = month.months.ago
  if end_of_month_reports.include?(report_type)
    as_of_date = as_of_date.end_of_month
  end
  step %{I should see a "#{report_type}" report as of "#{as_of_date}"}
end

Then(/^I should see a "(.*?)" report as of today$/) do |report_type|
  step %{I should see a "#{report_type}" report as of "#{Time.zone.today}"}
end

Then(/^I should see a "(.*?)" report as of last business day$/) do |report_type|
  step %{I should see a "#{report_type}" report as of "#{most_recent_business_day(Time.zone.today - 1)}"}
end

Then(/^I should see a "(.*?)" report as of the last day of last month relative to today$/) do |report_type|
  date = (@today - 1.month).end_of_month
  step %{I should see a "#{report_type}" report as of "#{date}"}
end

Then(/^I should see a "(.*?)" report as of "(.*?)"$/) do |report_type, as_of_date|
  step 'I wait for the report to load'
  as_of_date = as_of_date.to_date
  summary_statement = case report_type
    when "Advances Detail"
      report_summary_with_date('reports.pages.advances_detail.total_current_par_heading', fhlb_date_long_alpha(as_of_date))
    when 'Securities Services Monthly Statement'
      report_summary_with_date('reports.pages.securities_services_statement.heading', fhlb_date_long_alpha(as_of_date))
    when 'Monthly Securities Position'
      report_summary_with_date("reports.pages.securities_position.all_securities.total_original_par_heading", fhlb_date_long_alpha(as_of_date))
    else raise "unknown report type"
  end
  expect(page.find(".datepicker-trigger input").value).to eq(I18n.t('datepicker.single.input', date: fhlb_date_standard_numeric(as_of_date)))
  step %{I should see "#{strip_tags(summary_statement)}"}
end

Then(/^I should see a "(.*?)" with data for dates between the (\d+)(?:st|rd|th) through the (\d+)(?:st|rd|th) of (this|last) month$/) do |report_type, start_day, end_day, month|
  if month == 'this'
    start_date_obj = Date.new(@today.year, @today.month, start_day.to_i)
    end_date_obj = Date.new(@today.year, @today.month, end_day.to_i)
  elsif month == 'last'
    start_date_obj = (Date.new(@today.year, @today.month, start_day.to_i) - 1.month)
    end_date_obj = (Date.new(@today.year, @today.month, end_day.to_i) - 1.month)
  end
  step %{I should see a "#{report_type}" with dates between "#{start_date_obj}" and "#{end_date_obj}"}
end

Then(/^I should see a "(.*?)" with dates between "(.*?)" and "(.*?)"$/) do |report_type, start_date, end_date|
  # TODO add a null check for the case where no data is returned at all
  start_date_obj = start_date.to_date
  end_date_obj = end_date.to_date
  case report_type
    when "Settlement Transaction Account Statement"
      opening_balance = report_summary_with_date('reports.pages.settlement_transaction_account.opening_balance_heading', nil)
      closing_balance = report_summary_with_date('reports.pages.settlement_transaction_account.closing_balance_heading', nil)
    when "Capital Stock Activity Statement"
      opening_balance = report_summary_with_date('reports.pages.capital_stock_activity.opening_balance_heading', nil)
      closing_balance = report_summary_with_date('reports.pages.capital_stock_activity.closing_balance_heading', nil)
    else raise "unknown report type"
  end
  expect(page.find(".datepicker-trigger input").value).to eq("#{start_date_obj.strftime('%m/%d/%Y')} - #{end_date_obj.strftime('%m/%d/%Y')}")
  returned_start_date = page.find('.report-summary-data:nth-child(1) h3').text.gsub(strip_tags(opening_balance), '').to_date
  returned_end_date = page.find('.report-summary-data:nth-child(2) h3').text.gsub(strip_tags(closing_balance), '').to_date
  expect(start_date_obj).to be <= returned_start_date
  expect(end_date_obj).to be >= returned_end_date
  report_dates_in_range?(start_date_obj, end_date_obj)
end

When(/^I filter the report by "(.*?)"$/) do |text|
  page.find('.report-inputs .dropdown-selection').click
  page.find('li', text: text).click
end

Then(/^I should see a (current|monthly) securities position report for (Pledged|Unpledged) Securities$/) do |report_type, filter_type|
  table_header = page.find('.report-table-title').text
  expect(table_header).to include(filter_type)
  if !page.find(".report-table tbody tr:first-child td:first-child")['class'].split(' ').include?('dataTables_empty')
    filter_type = filter_type == 'Pledged' ? I18n.t('reports.pages.securities_position.pledged') : I18n.t('reports.pages.securities_position.unpledged')
    security_types = page.all(:xpath, "//*[@class='report-detail-cell']//td[text()='#{I18n.t('reports.pages.securities_position.custody_account_type')}']/following-sibling::td")
    security_types.each do |security_type|
      expect(security_type.text).to eq(filter_type)
    end
  end
end

When(/^I select "(.*?)" from the (credit|collateral) type selector$/) do |credit_type, selector|
  page.find(".#{selector}-type-filter .dropdown-selection").click
  page.find('li', text: credit_type, visible: true).click
end

When(/^I request a PDF$/) do
  export_report I18n.t('global.pdf')
end

Then(/^I should begin downloading a file$/) do
  page.assert_selector('body.report-download-started', wait: 180)
end

When(/^I request an XLSX$/) do
  export_report I18n.t('global.excel')
end

def export_report(format)
  single_item_dropdown = page.all('.report-header-buttons .dropdown.single-item-dropdown')
  jquery_execute("$('body').on('reportDownloadStarted', function(){$('body').addClass('report-download-started')})")
  page.find(".report-header-buttons .dropdown-selection").click
  unless single_item_dropdown.present?
    page.find('.report-header-buttons .dropdown li', text: format, visible: true).click
    click_button(I18n.t('dashboard.actions.download'))
  end
end

When(/^I click on the view cell for the first (advance|cash projection|security)/) do |report_type|
  case report_type
    when 'advance'
      column_name = I18n.t('common_table_headings.advance_number')
      row_offset = 1
    when 'cash projection'
      column_name = I18n.t('common_table_headings.cusip')
      row_offset = 1
    when 'security'
      column_name = I18n.t('reports.pages.securities_position.security_pledge_type')
      row_offset = 2
  end
  skip_if_table_empty do
    column_index = jquery_evaluate("$('.report-table thead th:contains(#{column_name})').index()") + row_offset
    @row_identifier = page.find(".report-table tbody tr:first-child td:nth-child(#{column_index})").text
    page.find('.report-table tr:first-child .detail-view-trigger').click
  end
end

Then(/^I should see the detailed view for the first (advance|cash projection|security)/) do |report_type|
  text = report_type == 'advance' ? I18n.t('reports.pages.advances_detail.record_title', advance_number: @row_identifier) : I18n.t('common_table_headings.cusip_title', cusip: @row_identifier)
  skip_if_table_empty do
    page.assert_selector('.report-table tr:first-child .report-detail-cell', visible: true)
    page.assert_selector('.report-table tr:first-child .report-detail-cell h3', text: text, visible: true)
    remove_instance_variable(:@row_identifier)
  end
end

When(/^I click on the hide link for the first (advance|cash projection|security)$/) do |report_type|
  skip_if_table_empty do
    page.find('.report-table tr:first-child .report-detail-cell .hide-detail-view').click
  end
end

Then(/^I should not see the detailed view for the first (advance|cash projection|security)$/) do |report_type|
  skip_if_table_empty do
    page.assert_selector('.report-table tr:first-child .report-detail-cell', visible: :hidden)
  end
end

def sleep_if_close_to_midnight
  now = Time.zone.now
  seconds_till_tomorrow = (now.tomorrow.beginning_of_day - now) * 1.days
  if seconds_till_tomorrow <= 30
    sleep(seconds_till_tomorrow + 1)
  end
end

def report_dates_in_range? (start_date, end_date, date_format="%m/%d/%Y")
  page.all('.report-table tbody td:first-child').each do |element|
    if element['class'].split(' ').include?('dataTables_empty')
      next
    end
    date = Date.strptime(element.text, date_format)
    raise Capybara::ExpectationNotMet, "date #{date} out of range [#{start_date}, #{end_date}]" unless date >= start_date && date <= end_date
  end
end

Then(/^I should see VRC current price indications report$/) do
  page.assert_selector('.current-price-vrc-table tbody tr:first-child td')
end

Then(/^I should see FRC current price indications report$/) do
  page.assert_selector('.current-price-frc-table tbody tr:first-child td')
end

Then(/^I should see ARC current price indications report$/) do
  page.assert_selector('.current-price-arc-table tbody tr:first-child td')
end

Then(/^I should see Capital Stock Trial Balance report$/) do
  page.assert_selector('.report-capital-stock-trial-balance table tbody tr:first-child td')
end

Then(/^I should see STA rates report$/) do
  page.assert_selector('.sta-rate-table tbody tr:last-child td')
end

Then(/^I should see Interest Rate Resets report$/) do
  page.assert_selector('.interest-rate-resets-table tbody tr:first-child td')
end

Then(/^I should see the report download flyout$/) do
  page.assert_selector('.flyout-loading-message', visible: true)
end

Then(/^I should not see the report download flyout$/) do
  page.assert_no_selector('.flyout-loading-message')
  page.assert_selector('.flyout', visible: :hidden)
end

Then(/^I should see Securities Transactions report$/) do
  page.assert_selector('.securities-transactions-table tbody tr:first-child td')
end

Then(/^I should see a security that is indicated as a new transaction$/) do
  page.first('.securities-transactions-table tbody tr td', text: /.\*\z/)
end

When(/^I cancel the report download from the flyout$/) do
  jquery_execute("$('body').on('reportDownloadCanceled', function(){$('body').addClass('report-download-canceled')})")
  page.find('.cancel-report-download', text: /#{I18n.t('global.cancel_download')}/i).click
end

Then(/^the report download should be canceled$/) do
  page.assert_selector('body.report-download-canceled')
end

When(/^I select "(.*?)" from the authorizations filter$/) do |text|
  page.find('.report-inputs .dropdown-selection').click
  page.find('.authorizations-filter li', text: text).click
end

When(/^I should only see users with the "(.*?)" role( or with inclusive roles)?$/) do |role, inclusive|
  step %{I wait for the report to load}

  role_mapping = {
    'Resolution and Authorization' => I18n.t('user_roles.resolution.title'),
    'Entire Authority' => I18n.t('user_roles.entire_authority.title'),
    'Advances' => I18n.t('user_roles.advances.title'),
    'Affordable Housing Program' => I18n.t('user_roles.affordable_housing.title'),
    'Collateral' => I18n.t('user_roles.collateral.title'),
    'Money Market Transactions' => I18n.t('user_roles.money_market.title'),
    'Interest Rate Derivatives' => I18n.t('user_roles.interest_rate_derivatives.title'),
    'Securities Services' => I18n.t('user_roles.securities.title'),
    'Wire Transfer Services' => I18n.t('user_roles.wire_transfer.title'),
    'Access Manager' => I18n.t('user_roles.access_manager.title'),
    'eTransact Holder' => I18n.t('user_roles.etransact.title'),
    'User' => I18n.t('user_roles.user.title')
  }
  role_name = role_mapping[role]
  page.all('.report-table tbody td:last-child').each do |cell|
    next if cell.text == I18n.t('errors.table_data_no_records')
    if inclusive && cell.has_no_selector?('li', text: role_name)
      cell.assert_selector('li', text: /\A#{Regexp.quote(I18n.t('global.footnoted_string', string: role_mapping['Resolution and Authorization']))}|#{Regexp.quote(I18n.t('global.footnoted_string', string: role_mapping['Entire Authority']))}\z/)
      page.assert_selector('small', text: I18n.t('reports.pages.authorizations.table_footnote', role: role_name.downcase.capitalize), exact: true)
    else
      cell.assert_selector('li', text: role_name, exact: true)
    end
  end
end

When(/^I click on the dividend transaction dropdown selector$/) do
  page.find('.dropdown-selection').click
end

When(/^I click on the securities services monthly statement dropdown selector$/) do
  page.find('.report-filter .dropdown-selection').click
end

Then(/^I should see a report for "(.*?)"$/) do |date|
  page.assert_selector('.report-summary-date', text: fhlb_date_long_alpha(date.to_date), exact: true)
end

When(/^I click on the last option in the dividend transaction dropdown selector$/) do
  page.find('.report-filter .dropdown li:last-child').click
end

When(/^I select "(.*?)" from the month year dropdown$/) do |monthyear|
  page.find('.report-filter .icon-chevron-after').click
  page.find('li', text: monthyear).click
end

Then(/^I should see a dividend summary for the last option in the dividend transaction dropdown selector$/) do
  page.find('.dropdown-selection').click
  text = page.find('.dropdown li:last-child').text
  page.assert_selector('.table-dividend-summary tr:first-child td:last-child', text: text)
end

Then(/^I should see the has no data state for the Securities Services Monthly Statement$/) do
  page.assert_selector('p', text: I18n.t('reports.pages.securities_services_statement.data_unavailable'), exact: true)
  page.assert_no_selector('.report-header-buttons')
  page.assert_no_selector('.report-inputs')
  page.assert_no_selector('.securities-services-table-wrapper')
  page.assert_no_selector('.report-summary-data')
end

When(/^I select the last entry from the month year dropdown$/) do
  page.find('.report-filter .dropdown-selection').click
  page.find('.report-filter .dropdown li:last-child').click
end

Then(/^I should see a report for the last entry from the month year dropdown$/) do
  element = page.find('.report-filter .dropdown li:last-child', visible: false)
  # this logic is not 100% rock solid, but it should work in most cases. Really it should
  # use the debit date from that report's debit_date field, however getting that into the
  # report is tricky.
  debit_date = most_recent_business_day(element['data-dropdown-value'].to_date + 1.month)
  step %{I should see a report for "#{debit_date}"}
end

Then(/^I should be on the "(.*?)" report page$/) do |report|
  text = case report
    when 'Settlement Transaction'
      I18n.t('reports.pages.settlement_transaction_account.title')
    when 'Borrowing Capacity'
      I18n.t('global.borrowing_capacity')
    when 'Capital Stock Position and Leverage'
      I18n.t('reports.pages.capital_stock_and_leverage.title')
    when 'Account Summary'
      I18n.t('reports.pages.account_summary.title')
  end
  page.assert_selector('.report h1', text: text, exact: true)
end
