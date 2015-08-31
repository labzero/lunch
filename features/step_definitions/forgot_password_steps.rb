When(/^I follow the forgot password link$/) do
  click_link(I18n.t('welcome.forgot_password'))
end

Then(/^I should see the forgot password page$/) do
  page.assert_selector('form legend', exact: true, visible: true, text: I18n.t('welcome.forgot_password'))
  page.assert_selector('form p', exact: true, visible: true, text: I18n.t('forgot_password.instructions'))
end

When(/^I enter my username$/) do
  fill_in('user_username', with: primary_user['username'])
end

When(/^I submit the form$/) do
  page.find('form input[type=submit]').click
end

Then(/^I should see the forgot password confirmation page$/) do
    page.assert_selector('form legend', exact: true, visible: true, text: I18n.t('forgot_password.confirmation.title'))
end

When(/^I enter an invalid username$/) do
  fill_in('user_username', with: 'abcd123')
end

Then(/^I should see an unknown user error flash$/) do
  page.assert_selector('form .form-flash-message', exact: true, visible: true, text: I18n.t('devise.passwords.username_not_found'))
end