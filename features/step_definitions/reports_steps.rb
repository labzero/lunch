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
  visit '/reports/capital-stock-activity'
end

When(/^I click the Certificate Sequence column heading$/) do
  page.find('th', text: I18n.t('reports.pages.capital_stock_activity.certificate_sequence')).click
end

When(/^I click the Date column heading$/) do
  page.find('th', text: I18n.t('global.date')).click
end

Then(/^I should see the "(.*?)" column values in "(.*?)" order$/) do |column_name, sort_order|
  case column_name
    when "Date"
      top_val = Date.strptime(page.find("tbody tr:first-child td:nth-child(1)").text, '%m/%d/%Y')
      bottom_val = Date.strptime(page.find("tbody tr:last-child td:nth-child(1)").text, '%m/%d/%Y')
    when "Certificate Sequence"
      top_val = page.find("tbody tr:first-child td:nth-child(2)").text.to_i
      bottom_val = page.find("tbody tr:last-child td:nth-child(2)").text.to_i
    else
      raise "column_name not recognized"
  end
  if sort_order == 'ascending'
    expect(top_val < bottom_val).to eq(true)
  elsif sort_order == 'descending'
    expect(top_val > bottom_val).to eq(true)
  else
    raise 'sort_order not recognized'
  end
end
