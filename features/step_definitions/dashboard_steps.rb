require 'action_view'
require_relative '../../app/helpers/custom_formatting_helper'
include CustomFormattingHelper

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

Then(/^I should not see the quick-advance module$/) do
  page.assert_no_selector('.dashboard-module-advances')
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
end

Then(/^I should see an? "(.*?)" in the Account module/) do |component|
  mod = page.find('.dashboard-module', :text => I18n.t('dashboard.your_account.title'))
  selector = case component
    when 'borrowing capacity gauge'
      '.dashboard-borrowing-capacity'
    when 'financing availability gauge'
      '.dashboard-financing-availability'
    when 'anticipated activity graph'
      '.dashboard-anticipated-activity-graph'
    else
      raise 'Unknown component for Account module'
  end
  mod.assert_selector(selector)
end

Then(/^I should see a flyout$/) do
  page.assert_selector('.flyout', visible: true)
end

Then(/^I should see "(.*?)" in the quick advance flyout input field$/) do |text|
  expect(page.find('.flyout-top-section input').value()).to eq(text)
end


When(/^I open the quick advance flyout$/) do
  @amount = Random.rand(100000000)
  step "I enter \"#{@amount}\" into the \".dashboard-module-advances input\" input field"
  step "I should see a flyout"
  sleep 0.5 # we select a rate after the flyout opens, but in some cases selenium does its checks before that JS fires
end

When(/^I click on the flyout close button$/) do
  page.find('.flyout-close-button').click
end

Then(/^I should not see a flyout$/) do
  page.assert_selector('.flyout', :visible => :hidden)
end

Then(/^I should see the quick advance table$/) do
  page.assert_selector('.dashboard-quick-advance-flyout table', visible: true)
end

Then(/^I should not see the quick advance table$/) do
  page.assert_selector('.dashboard-quick-advance-flyout table', :visible => :hidden)
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
  @rate_term = term
  @rate_type = type
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
  page.assert_selector('.quick-advance-preview', visible: true)
  #valdiate_passed_advance_params
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
  page.assert_selector('.quick-advance-summary dt', text: "Advance Number:", visible: true)
  valdiate_passed_advance_params
end

Then(/^I should not see the quick advance preview message$/) do
  page.assert_no_selector('.quick-advance-preview-message');
end

Then(/^I should see the quick advance confirmation close button$/) do
  page.assert_selector('.quick-advance-confirmation .primary-button', text: I18n.t('global.close').upcase, visible: true)
end

Then(/^I should see the quick advance interstitial$/) do
  page.assert_selector('.quick-advance-body .quick-advance-loading-message', visible: true)
end

Given(/^I am on the quick advance preview screen$/) do
  step "I open the quick advance flyout"
  step "I select the rate with a term of \"overnight\" and a type of \"whole\""
  step "I click on the initiate advance button"
  step "I should not see the quick advance table"
  step "I should see a preview of the quick advance"
end

Then(/^I successfully execute a quick advance$/) do
  step "I open the quick advance flyout"
  step "I select the rate with a term of \"overnight\" and a type of \"whole\""
  step "I click on the initiate advance button"
  step "I should not see the quick advance table"
  step "I should see a preview of the quick advance"
  step "I enter my SecurID pin and token"
  step "I click on the quick advance confirm button"
  step "I should see confirmation number for the advance"
  step "I should not see the quick advance preview message"
  step "I should see the quick advance confirmation close button"
end

When(/^I click on the quick advance confirmation close button$/) do
  page.find('.quick-advance-confirmation .primary-button', text: I18n.t('global.close').upcase).click
  sleep 1
end

Then(/^the Aggregate 30 Day Terms graph should show the Temporarily Unavailable state$/) do
  page.assert_selector('.dashboard-module-market .dashboard-module-temporarily-unavailable', text: I18n.t('global.temporarily_unavailable'))
end

When(/^there is no data for "(.*?)"$/) do |data|
  # this step may be used in the future to conditionally shut off certain endpoints or otherwise mock the experience of no data returned
end

Given(/^I enter my SecurID pin$/) do
  page.find('input[name=securid_pin').set(Random.rand(9999).to_s.rjust(4, '0'))
end

Given(/^I enter my SecurID token$/) do
  page.find('input[name=securid_token').set(Random.rand(999999).to_s.rjust(6, '0'))
end

When(/^I enter "([^"]*)" for my SecurID (pin|token)$/) do |value, field|
  page.find("input[name=securid_#{field}]").set(value)
end

Then(/^I shouldn't see the SecurID fields$/) do
  page.assert_no_selector("input[name=securid_pin]")
  page.assert_no_selector("input[name=securid_token]")
end

Given(/^I enter my SecurID pin and token$/) do
  step %{I enter my SecurID pin}
  step %{I enter my SecurID token}
end

Then(/^I should see SecurID errors$/) do
  page.assert_selector('.quick-advance-preview .form-error', visible: true)
  page.assert_selector('.quick-advance-preview input.input-field-error', visible: true)
end

def valdiate_passed_advance_params
  page.assert_selector('.quick-advance-summary span', visible: true, text: fhlb_formatted_currency(@amount, html: false, precision: 0))
  page.assert_selector('.quick-advance-summary dd', visible: true, text: I18n.t("dashboard.quick_advance.table.axes_labels.#{@rate_term}"))
  rate_type_text = case @rate_type
  when 'whole'
    I18n.t('dashboard.quick_advance.table.whole_loan')
  when 'aaa', 'aa', 'agency'
    I18n.t("dashboard.quick_advance.table.#{@rate_type}")
  else
    I18n.t('global.none')
  end
  page.assert_selector('.quick-advance-summary dd', visible: true, text: rate_type_text)
end
