Then(/^I should see the guides page$/) do
  page.assert_selector('.resource-guide-page')
end

Given(/^I am on the guides page$/) do
  visit '/resources/guides'
end

Then(/^I should see at least one guide$/) do
  page.assert_selector('.resource-guide-page .resource-guide', minimum: 1)
end

Then(/^I should see at least one guide update summary$/) do
  page.assert_selector('.resource-guide-page .resource-guide-update', minimum: 1)
end
