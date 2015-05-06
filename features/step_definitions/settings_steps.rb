When(/^I click on the gear icon in the header$/) do
  page.find('.main-nav a.icon-gear-after').click
end

Then(/^I should see "(.*?)" as the sidebar title$/) do |title|
  page.assert_selector('.sidebar-label', :text => title)
end

When(/^I click on "(.*?)" in the sidebar nav$/) do |link|
  page.find('.sidebar a', text: link).click
end

Then(/^I should be on the email settings page$/) do
  page.assert_selector('section.settings-email', :visible => true)
end

Then(/^I should be on the two factor settings page$/) do
  page.assert_selector('section.settings-two-factor',  visible: true)
  text = I18n.t('settings.two_factor.title')
  page.assert_selector('h1', visible: true, text: /\A#{Regexp.quote(text)}\z/)
  page.assert_selector('.settings-group', visible: true, count: 2)
end

When(/^I am on the email settings page$/) do
  visit "/settings"
  step "I click on \"Emails\" in the sidebar nav"
  step "I should be on the email settings page"
end

Given(/^I see the unselected state for the "(.*?)" option$/) do |option|
  page.assert_selector(".settings-email-#{option}-row td:nth-child(3) .settings-selected-item-message", :visible => :hidden)
end

When(/^I check the box for the "(.*?)" option$/) do |option|
  page.find(".settings-email-#{option}-row label").click
end

Then(/^I should see the selected state for the "(.*?)" option$/) do |option|
  page.assert_selector(".settings-email-#{option}-row td:nth-child(3) .settings-selected-item-message", :visible => true)
end

Then(/^I should see the auto\-save message for the email settings page$/) do
  page.assert_selector(".settings-save-message")
end