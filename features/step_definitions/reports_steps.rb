When(/^I click on the reports link in the header$/) do
  page.find('.page-header .secondary-nav a', text: 'Reports').click
end

Then(/^I should see "(.*?)" as the report page's main title$/) do |title|
  page.assert_selector('h1', text: title)
end

Then(/^I should see a table of "(.*?)" reports$/) do |title|
  page.assert_selector('.reports-table th', text: title)
end
