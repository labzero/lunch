When /^I visit the dashboard$/ do
  visit "/dashboard"
end

Then /^I should see dashboard modules$/ do
  page.assert_selector('.dashboard-module', :minimum => 1)
end