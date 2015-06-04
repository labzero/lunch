When(/^I edit a user$/) do
  page.find('tr:first-child .settings-user-edit a').click
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

When(/^I enter "([^"]*)" for the (email|email confirmation|first name|last name|)$/) do |value, field|
  attribute = attribute_for_user_field(field)

  step %{I enter "#{value}" into the "input[name=\"user[#{attribute}]\"]" input field}
end

When(/^I submit the edit user form$/) do
  page.find('.settings-users-overlay button', text: /\A#{Regexp.quote(I18n.t('settings.account.edit.save').upcase)}\z/).click
end

Then(/^I should a update user success overlay$/) do
  page.assert_selector('.settings-users-overlay h3', text: /\A#{Regexp.quote(I18n.t('settings.account.update.title'))}\z/, visible: true)
end

Then(/^I should see a (blank|confirmation mismatch) (first name|last name|email|email confirmation) error$/) do |type, field|
  case type
  when 'blank'
    error_type = type.to_sym
  when 'confirmation mismatch'
    error_type = :confirmation
  else
    raise 'unknown field type'
  end

  attribute = attribute_for_user_field(field)
  message = User.new.errors.generate_message(attribute, error_type)
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

def attribute_for_user_field(field)
  case field
  when 'email', 'email confirmation'
    attribute = field.parameterize('_')
  when 'first name'
    attribute = 'given_name'
  when 'last name'
    attribute = 'surname'
  else
    raise 'unknown field'
  end
  attribute
end
