When /^I visit the dashboard$/ do
  visit "/dashboard"
end

Then /^I should see dashboard modules$/ do
  page.assert_selector('.dashboard-module', :minimum => 1)
end

Then(/^I should see (\d+) contacts$/) do |count|
  mod = page.find('.dashboard-module-contact', :text => I18n.t('dashboard.contacts.title'))
  mod.assert_selector('.dashboard-contact', :minimum => count)
end