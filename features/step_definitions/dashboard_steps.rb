require 'action_view'
require_relative '../../app/helpers/custom_formatting_helper'
require_relative '../../app/helpers/contact_information_helper'
require_relative '../../app/helpers/reports_helper'
include CustomFormattingHelper
include ContactInformationHelper
include ReportsHelper
include ActionView::Helpers::SanitizeHelper

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

Then(/^I should see the "(.*?)" section in its loaded state$/) do |section|
  mod = get_module_by_section(section)
  mod.assert_no_selector('.dashboard-module-loading', wait: 180)
  case section
    when 'recent activities'
      mod.assert_selector('.table-dashboard-recent-activity') unless mod.has_css?('.dashboard-module-recent-activity-no-data')
    when 'account overview'
      mod.assert_selector('.table-dashboard-account-overview')
  end
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
    else
      raise 'Unknown component for Account module'
  end
  mod.assert_selector(selector)
end

Then(/^the Aggregate 30 Day Terms graph should show the Temporarily Unavailable state$/) do
  page.assert_selector('.dashboard-module-market .dashboard-module-temporarily-unavailable', text: I18n.t('global.temporarily_unavailable'))
end

When(/^there is no data for "(.*?)"$/) do |data|
  # this step may be used in the future to conditionally shut off certain endpoints or otherwise mock the experience of no data returned
end

When(/^I am on the dashboard with the account overview in its loaded state$/) do
  step 'I visit the dashboard'
  step %{I should see the "account overview" section in its loaded state}
end

When(/^I click on the (STA Balance|Collateral Borrowing Capacity|Stock Leverage) link in the account overview$/) do |link|
  text = case link
    when 'STA Balance'
      I18n.t('dashboard.your_account.table.balance')
    when 'Collateral Borrowing Capacity'
      I18n.t('dashboard.your_account.table.remaining.capacity')
    when 'Stock Leverage'
      I18n.t('dashboard.your_account.table.remaining.leverage')
  end
  page.find('.table-dashboard-account-overview a', text: text, exact: true).click
end

def get_module_by_section(section)
  heading = case section
    when 'recent activities'
      I18n.t('dashboard.recent_activity.title')
    when 'account overview'
      I18n.t('dashboard.your_account.title')
  end
  page.find('.dashboard-module', text: heading, exact: true)
end