When(/^I click on the reports link in the header$/) do
  page.find('.page-header .secondary-nav a', text: I18n.t('reports.title')).click
end

Then(/^I should see "(.*?)" as the report page's main title$/) do |title|
  page.assert_selector('h1', text: title)
end

Then(/^I should see a table of "(.*?)" reports$/) do |title|
  page.assert_selector('.reports-table th', text: title)
end

Given(/^I don't see the reports dropdown$/) do
  page.find('.logo').hover # make sure the mouse isn't left on top of the reports dropdown from a different test
  report_menu = page.find('.nav-menu', text: I18n.t('reports.title'))
  report_menu.parent.assert_selector('.nav-dropdown', visible: :hidden)
end

When(/^I hover on the reports link in the header$/) do
  page.find('.nav-menu', text: I18n.t('reports.title')).hover
end

Then(/^I should see the reports dropdown$/) do
  report_menu = page.find('.nav-menu', text: I18n.t('reports.title'))
  report_menu.parent.assert_selector('.nav-dropdown', visible: true)
end

Given(/^I am on the reports summary page$/) do
  visit "/reports"
end

When(/^I select "(.*?)" from the reports dropdown$/) do |report|
  step 'I hover on the reports link in the header'
  page.click_link(report)
end

Then(/^I should see report summary data$/) do
  page.assert_selector('.report-summary-data', visible: true)
end

Then(/^I should see a report table with multiple data rows$/) do
  page.assert_selector('.report-table')
  expect(page.all('.report-table tbody tr').length).to be > 0
end

Given(/^I am on the Capital Stock Activity Statement page$/) do
  now = DateTime.now
  seconds_till_tomorrow = (now.tomorrow.beginning_of_day - now) * 1.days
  if seconds_till_tomorrow <= 30
    sleep(seconds_till_tomorrow + 1)
  end
  @today = Date.today
  visit '/reports/capital-stock-activity'
end

When(/^I click the Certificate Sequence column heading$/) do
  page.find('th', text: I18n.t('reports.pages.capital_stock_activity.certificate_sequence')).click
end

When(/^I click the Date column heading$/) do
  page.find('th', text: I18n.t('global.date')).click
end

Then(/^I should see a Capital Stock Activity Statement for the current month to date$/) do
  start_date = @today.beginning_of_month.strftime('%B %-d, %Y')
  end_date = @today.strftime('%B %-d, %Y')
  step %{I should see a Capital Stock Activity Statement starting on "#{start_date}" and ending on "#{end_date}"}
end

Then(/^I should see a Capital Stock Activity Statement for the last month$/) do
  last_month = (@today.beginning_of_month - 1.months)
  start_date = last_month.strftime('%B %-d, %Y')
  end_date = last_month.end_of_month.strftime('%B %-d, %Y')
  step %{I should see a Capital Stock Activity Statement starting on "#{start_date}" and ending on "#{end_date}"}
end

Then(/^I should see a Capital Stock Activity Statement for the (\d+)(?:st|rd|th) through the (\d+)(?:st|rd|th) of this month$/) do |start_day, end_day|
  start_date = Date.new(@today.year, @today.month, start_day.to_i).strftime('%B %-d, %Y')
  end_date = Date.new(@today.year, @today.month, end_day.to_i).strftime('%B %-d, %Y')
  step %{I should see a Capital Stock Activity Statement starting on "#{start_date}" and ending on "#{end_date}"}
end

Then(/^I should see a Capital Stock Activity Statement starting on "(.*?)" and ending on "(.*?)"$/) do |start_date, end_date|
  expect(page.find(".datepicker-trigger input").value).to eq("#{start_date} - #{end_date}")
  opening_balance = I18n.t('reports.pages.capital_stock_activity.opening_balance_heading', date: start_date)
  closing_balance = I18n.t('reports.pages.capital_stock_activity.closing_balance_heading', date: end_date)
  step %{I should see "#{opening_balance}"}
  step %{I should see "#{closing_balance}"}
  start_date_obj = start_date.to_date
  end_date_obj = end_date.to_date
  page.all('.report-table tbody td:first-child').each do |element|
    if element['class'].split(' ').include?('dataTables_empty')
      next
    end
    date = Date.strptime(element.text, "%m/%d/%Y")
    raise Capybara::ExpectationNotMet, "date #{date} out of range [#{start_date_obj}, #{end_date_obj}]" unless date >= start_date_obj && date <= end_date_obj
  end
end
