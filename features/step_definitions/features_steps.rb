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
