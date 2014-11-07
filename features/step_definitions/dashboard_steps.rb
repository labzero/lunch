When /^I visit the dashboard$/ do
  visit "/dashboard"
end

Then /^I should see dashboard modules$/ do
  page.assert_selector('.dashboard-module', :minimum => 1)
end

Then(/^I should see (\d+) contacts$/) do |count|
  mod = page.find('.dashboard-module', :text => I18n.t('dashboard.contacts.title'))
  mod.assert_selector('.dashboard-contact', :minimum => count)
end

Then(/^I should see a dollar amount field$/) do
  mod = page.find('.dashboard-module', :text => I18n.t('dashboard.quick_advance.title'))
  mod.assert_selector('input')
end

Then(/^I should see an advance rate\.$/) do
  mod = page.find('.dashboard-module', :text => I18n.t('dashboard.quick_advance.title'))
  mod.assert_selector('.dashboard-advances-rate', :text => /\d+\.\d+\%/)
end
