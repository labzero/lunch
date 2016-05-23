When(/^I click on the Securities link in the header$/) do
  page.find('.secondary-nav a', text: I18n.t('securities.title'), exact: true).click
end

Then(/^I should be on the (Manage Securities|Securities Requests) page$/) do |page_type|
  text = case page_type
    when 'Manage Securities'
      I18n.t('securities.manage.title')
    when 'Securities Requests'
      I18n.t('securities.requests.title')
  end
  page.assert_selector('h1', text: text, exact: true)
  step 'I should see a report table with multiple data rows'
end

Given(/^I am on the securities requests page$/) do
  visit '/securities/requests'
end

Then(/^I should see two securities requests tables with data rows$/) do
  page.assert_selector('.securities-request-table', count: 2)
  page.all('.securities-request-table').each do |table|
    table.assert_selector('tbody tr')
  end
end
