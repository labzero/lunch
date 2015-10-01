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

Given(/^I am on the change password page$/) do
  page.find( '.icon-gear-after' ).click
  step %{I should see the change password page}
end

Then(/^I should see the change password page$/) do
  page.assert_selector('.settings-password form', visible: true)
end

Given(/^I fill in the current password field with the (password change user)'s password$/) do |user_type|
  fill_in(:user_current_password, with: user_for_type(user_type)['password'])
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

Given(/^I am on the two factor authentication settings page$/) do
  visit '/settings/two-factor'
end

Then(/^I should see the reset PIN form$/) do
  page.assert_selector('.settings-reset-pin form', visible: true)
end

When(/^I click on the reset token PIN CTA$/) do
  click_link I18n.t('settings.two_factor.reset_pin.cta')
end

When(/^I cancel resetting the PIN$/) do
  click_button I18n.t('global.cancel')
end

Then(/^I should not see the reset PIN form$/) do
  page.assert_selector('.settings-reset-pin form', visible: false)
end

Given(/^I am on the reset PIN page$/) do
  step %{I am on the two factor authentication settings page}
  step %{I click on the reset token PIN CTA}
end

When(/^I enter a bad current PIN$/) do
  page.find('input[name=securid_pin').set('abc1')
end

When(/^I submit the reset PIN form$/) do
  click_button I18n.t('settings.two_factor.reset_pin.save')
end

Then(/^I should see the invalid PIN message$/) do
  page.assert_selector('.form-error', text: /\A#{Regexp.quote(I18n.t('dashboard.quick_advance.securid.errors.invalid_pin'))}\z/, visible: true)
end

When(/^I enter a good current PIN$/) do
  step %{I enter my SecurID pin}
end

When(/^I enter a bad token$/) do
  page.find('input[name=securid_token').set('abc1dc')
end

Then(/^I should see the invalid token message$/) do
  page.assert_selector('.form-error', text: /\A#{Regexp.quote(I18n.t('dashboard.quick_advance.securid.errors.invalid_token'))}\z/, visible: true)
end

When(/^I enter a good token$/) do
  step %{I enter my SecurID token}
end

When(/^I enter a bad new PIN$/) do
  page.find('input[name=securid_new_pin').set('12ad')
end

When(/^I enter a good new PIN$/) do
  page.find('input[name=securid_new_pin').set(Random.rand(9999).to_s.rjust(4, '0'))
end

When(/^I enter a bad confirm PIN$/) do
  page.find('input[name=securid_confirm_pin').set('12ad')
end

When(/^I enter two different values for the new PIN$/) do
  pin = Random.rand(9999).to_s.rjust(4, '0')
  page.find('input[name=securid_new_pin').set(pin)
  page.find('input[name=securid_confirm_pin').set(pin)
end

Then(/^I should see the failed to reset PIN message$/) do
  page.assert_selector('.form-flash-message', text: /\A#{Regexp.quote(I18n.t('settings.two_factor.reset_pin.error'))}\z/, visible: true)
end

When(/^I click on the resynchronize token CTA$/) do
  click_link I18n.t('settings.two_factor.resynchronize.cta')
end

Then(/^I should see the resynchronize token form$/) do
  page.assert_selector('.settings-resynchronize-token form', visible: true)
end

When(/^I cancel resynchronizing the token$/) do
  click_button I18n.t('global.cancel')
end

Then(/^I should not see the resynchronize token form$/) do
  page.assert_selector('.settings-resynchronize-token form', visible: false)
end

Given(/^I am on the resynchronize token page$/) do
  step %{I am on the two factor authentication settings page}
  step %{I click on the resynchronize token CTA}
end

When(/^I submit the resynchronize token form$/) do
  click_button I18n.t('settings.two_factor.resynchronize.save')
end

When(/^I enter a bad next token$/) do
  page.find('input[name=securid_next_token').set('abc1dc')
end

When(/^I enter a good next token$/) do
  page.find('input[name=securid_next_token').set(Random.rand(999999).to_s.rjust(6, '0'))
end

Then(/^I should see the failed to resynchronize token message$/) do
    page.assert_selector('.form-flash-message', text: /\A#{Regexp.quote(I18n.t('settings.two_factor.resynchronize.error'))}\z/, visible: true)
end

Then(/^I should see current password validations$/) do
  step %{I enter a current password of ""}
  step %{I should see a current password required error}
end

When(/^I enter a current password of "([^"]*)"$/) do |password|
  fill_in(:user_current_password, with: password)
  page.find('body').click
end

Then(/^I should see a current password required error$/) do
  page.assert_selector('label.label-error', exact: true, visible: true, text: I18n.t('activerecord.errors.models.user.attributes.current_password.blank'))
end
