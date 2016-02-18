Then(/^I should see the capital plan page$/) do
  page.assert_selector('.resource-capital-plan-page')
end

Given(/^I am on the capital plan page$/) do
  visit '/resources/capital-plan'
end

Then(/^I should see the capital plan redemption$/) do
  page.assert_selector('.resource-capital-plan-page .resource-capital-plan-redemption', minimum: 1)
end


