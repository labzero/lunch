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
  sleep 0.5 # we select a rate after the flyout opens, but in some cases selenium does its checks before that JS fires
end

When(/^I click on the flyout close button$/) do
  page.find('.flyout-close-button').click
end

Then(/^I should not see a flyout$/) do
  page.assert_selector('.flyout', visible: false)
end

Then(/^I should see the quick advance table$/) do
  page.assert_selector('.dashboard-quick-advance-flyout table', visible: true)
end

Then(/^I should not see the quick advance table$/) do
  page.assert_selector('.dashboard-quick-advance-flyout table', visible: false)
end

Then(/^I should see a rate for the "(.*?)" term with a type of "(.*?)"$/) do |term, type|
  page.find(".dashboard-quick-advance-flyout td[data-advance-term='#{term}'][data-advance-type='#{type}']").text.should_not eql("")
end

When(/^I hover on the cell with a term of "(.*?)" and a type of "(.*?)"$/) do |term, type|
  page.find(".dashboard-quick-advance-flyout td[data-advance-term='#{term}'][data-advance-type='#{type}']").hover
end

Then(/^I should see the quick advance table tooltip for the cell with a term of "(.*?)" and a type of "(.*?)"$/) do |term, type|
  page.find(".dashboard-quick-advance-flyout td[data-advance-term='#{term}'][data-advance-type='#{type}'] .tooltip", visible: true)
end

When(/^I select the rate with a term of "(.*?)" and a type of "(.*?)"$/) do |term, type|
  page.find(".dashboard-quick-advance-flyout td[data-advance-term='#{term}'][data-advance-type='#{type}']").click
end

When(/^I see the unselected state for the cell with a term of "(.*?)" and a type of "(.*?)"$/) do |term, type|
  page.assert_no_selector(".dashboard-quick-advance-flyout td.cell-selected[data-advance-term='#{term}'][data-advance-type='#{type}']")
end

When(/^I see the deactivated state for the initiate advance button$/) do
  page.assert_no_selector(".dashboard-quick-advance-flyout .initiate-quick-advance.active")
end

Then(/^I should see the selected state for the cell with a term of "(.*?)" and a type of "(.*?)"$/) do |term, type|
  page.assert_selector(".dashboard-quick-advance-flyout td.cell-selected[data-advance-term='#{term}'][data-advance-type='#{type}']")
end

Then(/^the initiate advance button should be active$/) do
  page.assert_selector(".dashboard-quick-advance-flyout .initiate-quick-advance.active")
end

When(/^I click on the initiate advance button$/) do
  page.find(".dashboard-quick-advance-flyout .initiate-quick-advance.active", visible: true).click
end

Then(/^I should see a preview of the quick advance$/) do
  page.assert_selector(".quick-advance-preview", visible: true)
end

Then(/^I should not see a preview of the quick advance$/) do
  page.assert_no_selector(".quick-advance-preview")
end

When(/^I click on the back button for the quick advance preview$/) do
  page.find(".quick-advance-back-button", visible: true).click
end

When(/^I click on the quick advance confirm button$/) do
  page.find(".confirm-quick-advance").click
end

Then(/^I should see confirmation number for the advance$/) do
  page.assert_selector('.quick-advance-summary p', text: "Advance Number:", visible: true)
end

Then(/^I should not see the quick advance preview message$/) do
  page.assert_no_selector('.quick-advance-preview-message');
end

Then(/^I should see the quick advance confirmation close button$/) do
  page.assert_selector('.quick-advance-confirmation-button', visible: true)
end

Then(/^I successfully execute a quick advance$/) do
  step "I open the quick advance flyout"
  step "I select the rate with a term of \"overnight\" and a type of \"whole_loan\""
  step "I click on the initiate advance button"
  step "I should not see the quick advance table"
  step "I should see a preview of the quick advance"
  step "I click on the quick advance confirm button"
  step "I should see confirmation number for the advance"
  step "I should not see the quick advance preview message"
  step "I should see the quick advance confirmation close button"
end

When(/^I click on the quick advance confirmation close button$/) do
  page.find(".quick-advance-confirmation-button").click
end
