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

Then(/^I should see a market overview graph$/) do
  mod = page.find('.dashboard-module', :text => I18n.t('dashboard.market_overview.title'))
  mod.assert_selector('.dashboard-market-graph', :visible => true)
end

Then(/^I should see the Your Account table breakdown$/) do
  mod = page.find('.dashboard-module', :text => I18n.t('dashboard.your_account.title'))
  mod.assert_selector('td', :text => I18n.t('dashboard.your_account.table.balance'))
  mod.assert_selector('td', :text => I18n.t('dashboard.your_account.table.credit_outstanding'))
  mod.assert_selector('td', :text => I18n.t('dashboard.your_account.table.market_value.title'))
  mod.assert_selector('td', :text => I18n.t('dashboard.your_account.table.borrowing_capacity.title'))
end

Then(/^I should see the Anticipated Activity graph$/) do
  mod = page.find('.dashboard-module', :text => I18n.t('dashboard.your_account.title'))
  mod.assert_selector('.dashboard-anticipated-activity-graph')
end

Then(/^I should see a pledged collateral gauge$/) do
  mod = page.find('.dashboard-module', :text => I18n.t('dashboard.your_account.title'))
  mod.assert_selector('.dashboard-pledged-collateral')
  mod.assert_selector('.dashboard-gauge')
end

Then(/^I should see a total securities gauge$/) do
  mod = page.find('.dashboard-module', :text => I18n.t('dashboard.your_account.title'))
  mod.assert_selector('.dashboard-total-securities')
  mod.assert_selector('.dashboard-gauge')
end

Then(/^I should see an effective borrwoing capacity gauge$/) do
  mod = page.find('.dashboard-module', :text => I18n.t('dashboard.your_account.title'))
  mod.assert_selector('.dashboard-effective-borrowing-capacity')
  mod.assert_selector('.dashboard-gauge')
end

Then(/^I should see a flyout$/) do
  page.assert_selector('.flyout', visible: true)
end

Then(/^I should see "(.*?)" in the quick advance flyout input field$/) do |text|
  expect(page.find('.flyout-top-section input').value()).to eq(text)
end


When(/^I open the quick advance flyout$/) do
  step "I enter \"44503000\" into the \".dashboard-module-advances input\" input field"
  step "I should see a flyout"
end

When(/^I click on the flyout close button$/) do
  page.find('.flyout-close-button').click
end

Then(/^I should not see a flyout$/) do
  page.assert_selector('.flyout', visible: false)
end
