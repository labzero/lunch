Then(/^I see a list of features and their state$/) do
  table_class = '.admin-features-table'
  state_classes = ['.admin-conditional-icon', '.admin-on-icon', '.admin-off-icon']
  page.assert_selector("#{table_class} tbody tr", minimum: 1)
  state_selector = state_classes.collect {|k| k.prepend(table_class + ' ') }
  page.assert_selector(state_selector.join(', '), minimum: 1)
end

When(/^I am on the features list$/) do
  visit('/admin/features')
end

When(/^I click on the view feature link$/) do
  page.all('.admin-features-table a', text: /\A#{Regexp.quote(I18n.t('admin.features.index.actions.edit'))}\z/i, exact: true, minimum: 1).first.click
end

Then(/^I see a list of enabled members$/) do
  page.assert_selector('.admin-feature-edit h2', text: I18n.t('admin.features.edit.members'), visible: true)
end

Then(/^I see a list of enabled users$/) do
  page.assert_selector('.admin-feature-edit h2', text: I18n.t('admin.features.edit.users'), visible: true)
end

Then(/^I see an (enable|disable) feature button$/) do |action|
  i18n_key = action == 'enable' ? 'admin.features.confirmations.enable_all.accept' : 'admin.features.confirmations.disable_all.accept'
  page.assert_selector('.admin-feature-edit button:not([disabled])', text: /\A#{Regexp.quote(I18n.t(i18n_key))}\z/i, exact: true, visible: true)
end

When(/^I (enable|disable) the feature$/) do |action|
  i18n_key = action == 'enable' ? 'admin.features.confirmations.enable_all.accept' : 'admin.features.confirmations.disable_all.accept'
  button_regex = /\A#{Regexp.quote(I18n.t(i18n_key))}\z/i
  page.find('.admin-feature-edit button', text: button_regex, exact: true).click
  page.assert_selector('.flyout .admin-confirmation-dialog')
  page.find('.flyout .admin-confirmation-dialog .primary-button', text: button_regex, exact: true).click
end

Then(/^I see the feature (enabled|disabled) for everyone$/) do |state|
  icon_state = state == 'enabled' ? 'admin-on-icon' : 'admin-off-icon'
  page.assert_selector(".admin-feature-edit .#{icon_state}")
end


Given(/^the feature "([^"]*)" is (enabled|disabled)$/) do |feature_name, state|
  feature = Rails.application.flipper[feature_name]
  if state == 'enabled'
    feature.enable
  else
    feature.disable
  end
end

When(/^I click on the view feature link for "([^"]*)"$/) do |feature_name|
  row = page.find('.admin-features-table td', text: /\A#{Regexp.quote(feature_name)}\z/i, exact: true).find(:xpath, '..')
  row.find('a', text: /\A#{Regexp.quote(I18n.t('admin.features.index.actions.edit'))}\z/i, exact: true).click
end
