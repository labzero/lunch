When(/^I edit a user$/) do
  first(:link, I18n.t('global.edit')).click
end

When(/^I create a new user$/) do
  first(:link, I18n.t('settings.account.actions.add_user')).click
end

When(/^I visit the access manager page$/) do
  visit '/settings/users'
end

Then(/^I should see a list of users$/) do
  page.assert_selector('h1', text: /\A#{Regexp.quote(I18n.t('settings.account.title'))}\z/, visible: true)
  page.assert_selector('.settings-users-table tbody tr', minimum: 1, visible: true)
end

Then(/^I should not see "([^"]*)" in the sidebar nav$/) do |title|
  page.assert_no_selector('.sidebar-label', text: /\A#{Regexp.quote(title)}\z/, visible: true)
end

When(/^I lock a user$/) do
  first(:link, I18n.t('settings.account.actions.lock')).click
end

When(/^I reset the password for a user$/) do
  first(:link, I18n.t('settings.account.actions.reset_password')).click
end

Then(/^I should see a locked user success overlay$/) do
  page.assert_selector('.settings-users-overlay h3', text: /\A#{Regexp.quote(I18n.t('settings.account.lock.title'))}\z/, visible: true)
end

When(/^I dismiss the overlay$/) do
  page.find('.settings-users-overlay button', text: /\A#{Regexp.quote(I18n.t('global.close').upcase)}\z/).click
  page.assert_no_selector('.settings-users-overlay', visible: true)
end

When(/^I unlock a user$/) do
  first(:link, I18n.t('settings.account.actions.unlock')).click
end

Then(/^I should see an unlocked user success overlay$/) do
  page.assert_selector('.settings-users-overlay h3', text: /\A#{Regexp.quote(I18n.t('settings.account.unlock.title'))}\z/, visible: true)
end

Then(/^I should see an edit user form overlay$/) do
  page.assert_selector('.settings-users-overlay h3', text: /\A#{Regexp.quote(I18n.t('settings.account.edit.title'))}\z/, visible: true)
end

When(/^I cancel the overlay$/) do
  page.find('.settings-users-overlay button', text: /\A#{Regexp.quote(I18n.t('global.cancel').upcase)}\z/).click
  page.assert_no_selector('.settings-users-overlay', visible: true)
end

Then(/^I should not see an edit user form overlay$/) do
  page.assert_no_selector('.settings-users-overlay h3', text: /\A#{Regexp.quote(I18n.t('settings.account.edit.title'))}\z/, visible: true)
end

Then(/^I should not see any validations errors$/) do
  page.assert_no_selector('.form-error')
end

When(/^I enter "([^"]*)" for the (email|email confirmation|first name|last name|username)$/) do |value, field|
  attribute = attribute_for_user_field(field)

  step %{I enter "#{value}" into the "input[name=\"user[#{attribute}]\"]" input field}
  page.find('.settings-users-overlay h3').click # to change focus
end

When(/^I submit the edit user form$/) do
  page.find('.settings-users-overlay button', text: /\A#{Regexp.quote(I18n.t('settings.account.edit.save').upcase)}\z/).click
end

When(/^I submit the new user form$/) do
  page.find('.settings-users-overlay button', text: /\A#{Regexp.quote(I18n.t('settings.account.create.save').upcase)}\z/).click
end

Then(/^I should see an update user success overlay$/) do
  page.assert_selector('.settings-users-overlay h3', text: /\A#{Regexp.quote(I18n.t('settings.account.update.title'))}\z/, visible: true)
end

Then(/^I should see a new user success overlay$/) do
  page.assert_selector('.settings-users-overlay h3', text: /\A#{Regexp.quote(I18n.t('settings.account.confirm_create.title'))}\z/, visible: true)
end

Then(/^I should see a reset password overlay$/) do
  page.assert_selector('.settings-users-overlay h3', text: /\A#{Regexp.quote(I18n.t('settings.account.reset_password.title'))}\z/, visible: true)
end

Given(/^I edit the deletable user$/) do
  page.find('.settings-user-username', text: /\A#{Regexp.quote(deletable_user['username'])}\z/).find(:xpath, '..').find('.settings-user-edit').click
end

Given(/^I click the delete user button$/) do
  click_link(I18n.t('settings.account.edit.delete'))
end

When(/^I select a reason$/) do
  page.assert_selector('.settings-user-confirm-delete')
  first('.settings-user-confirm-delete input[type=radio]').click
end

Then(/^I should see the user deleted overlay$/) do
  page.assert_selector('.settings-users-overlay h3', text: /\A#{Regexp.quote(I18n.t('settings.account.delete_user.title'))}\z/, visible: true)
end

When(/^I submit the delete user form$/) do
  click_link_or_button(I18n.t('settings.account.confirm_delete.delete_button'))
end

Then(/^I should see the confirm delete overlay$/) do
  page.assert_selector('.settings-users-overlay h3', text: /\A#{Regexp.quote(I18n.t('settings.account.confirm_delete.title'))}\z/, visible: true)
end

Then(/^the confirm delete user button should be disabled$/) do
  page.assert_selector('.settings-user-confirm-delete .primary-button[disabled]')
end

Then(/^the confirm delete user button should be enabled$/) do
  page.assert_no_selector('.settings-user-confirm-delete .primary-button[disabled]')
  page.assert_selector('.settings-user-confirm-delete .primary-button')
end

When(/^I edit a non\-access manager$/) do
  element = nil
  page.all('.settings-user-username').each do |node|
    if node.text != access_manager['username']
      element = node
      break
    end
  end
  element.find(:xpath, '..').find('.settings-user-edit').click
end

When(/^I edit an access manager$/) do
  page.find('.settings-user-username', text: /\A#{Regexp.quote(access_manager['username'])}\z/).find(:xpath, '..').find('.settings-user-edit').click
end

Then(/^I should see the delete user button disabled$/) do
  page.assert_selector('.settings-user-delete[disabled]')
end

Then(/^I should see a (too short\[\d+\]|too long\[\d+\]|blank|invalid|confirmation mismatch) (first name|last name|username|email|email confirmation) error$/) do |type, field|
  case type
  when 'blank', 'invalid'
    error_type = type.to_sym
  when 'confirmation mismatch'
    error_type = :confirmation
  when /too short\[(\d+)\]/
    error_type = :too_short
    count = $1
  when /too long\[(\d+)\]/
    error_type = :too_long
    count = $1
  else
    raise 'unknown field type'
  end

  attribute = attribute_for_user_field(field)
  message = User.new.errors.generate_message(attribute, error_type)
  message = message[:other].sub( /\%\{count\}/, count ) if [:too_short, :too_long].include?(error_type)
  page.assert_selector('.label-error', text: /\A#{Regexp.quote(message)}\z/, visible: true)
end

Then(/^I should see a user with the an? (first name|last name|email) of "([^"]*)"$/) do |field, value|
  case field
  when 'email'
    selector = '.settings-user-email'
    regex = /\A#{Regexp.quote(value)}\z/
  when 'first name'
    selector = '.settings-user-name'
    regex = /\A#{Regexp.quote(value)} /
  when 'last name'
    selector = '.settings-user-name'
    regex = / #{Regexp.quote(value)}\z/
  else
    raise 'unknown field'
  end
  page.assert_selector(selector, text: regex, visible: true)
end

Then(/^I should see the (lock|reset-password|edit) user button disabled$/) do |type|
  page.assert_no_selector(".settings-user-#{type} a")
end

def attribute_for_user_field(field)
  case field
  when 'email', 'email confirmation'
    attribute = field.parameterize('_')
  when 'first name'
    attribute = 'given_name'
  when 'last name'
    attribute = 'surname'
    when 'username'
      attribute = 'username'
  else
    raise 'unknown field'
  end
  attribute
end
