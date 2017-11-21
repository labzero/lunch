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

When(/^I click on the Back to List link$/) do
  page.all('.admin-feature-list-link a', text: /\A#{Regexp.quote(I18n.t('admin.features.edit.back_to_list'))}\z/i, exact: true, minimum: 1).first.click
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

Given(/^the feature "([^"]*)" is conditionally enabled for the "([^"]*)" institution$/) do |feature_name, bank|
  feature = Rails.application.flipper[feature_name]
  id = (MembersService.new(ActionDispatch::TestRequest.new).all_members.find { |member|  member[:name] == bank })[:id]
  feature.enable_actor(Member.new(id))
end


When(/^I click on the view feature link for "([^"]*)"$/) do |feature_name|
  row = page.find('.admin-features-table td', text: /\A#{Regexp.quote(feature_name)}\z/i, exact: true).find(:xpath, '..')
  row.find('a', text: /\A#{Regexp.quote(I18n.t('admin.features.index.actions.edit'))}\z/i, exact: true).click
end

Then(/^I see an add institution button$/) do
  page.assert_selector('button', text: /\A#{Regexp.quote(I18n.t('admin.features.confirmations.add_member.accept'))}\z/i, exact: true, visible: true)
end

Then(/^I see a remove institution button$/) do
  page.assert_selector('.admin-feature-edit table:first-of-type .admin-feature-link-remove', visible: true)
end

When(/^I add the institution "([^"]*)"$/) do |bank|
  step %{I initiate adding an institution}
  step %{I select the institution "#{bank}"}
  page.find('.flyout .primary-button', text: /\A#{Regexp.quote(I18n.t('admin.features.confirmations.add_member.accept'))}\z/i, exact: true, visible: true).click
end

Then(/^I see the feature conditionally enabled$/) do
  page.assert_selector('.admin-feature-edit h1 .admin-conditional-icon', visible: true)
end

Then(/^I see "([^"]*)" in the enabled institution list$/) do |bank|
  page.assert_selector('.admin-feature-edit table:first-of-type td', text: bank)
end

When(/^I remove the institution "([^"]*)"$/) do |bank|
  row = page.find('.admin-feature-edit table:first-of-type td', text: bank)
  row.find('.admin-feature-link-remove').click
end

Then(/^I do not "([^"]*)" in the enabled institution list$/) do |bank|
  page.assert_no_selector('.admin-feature-edit td', text: bank)
end

When(/^I initiate adding an institution$/) do
  click_button(I18n.t('admin.features.confirmations.add_member.accept'))
end

When(/^I select the institution "([^"]*)"$/) do |bank|
  page.select(bank, from: :member_id)
end

When(/^I cancel adding an? (?:institution|user)$/) do
  click_button(I18n.t('global.cancel'))
end

When(/^I do not see "([^"]*)" in the enabled institution list$/) do |bank|
  page.assert_no_selector('.flyout .admin-confirmation-dialog', visible: true)
  page.assert_no_selector('.admin-feature-edit td', text: bank)
end

When(/^I initiate adding a user$/) do
  click_button(I18n.t('admin.features.confirmations.add_user.accept'))
end

Then(/^I see an add user button$/) do
  page.assert_selector('button', text: /\A#{Regexp.quote(I18n.t('admin.features.confirmations.add_user.accept'))}\z/i, exact: true, visible: true)
end

When(/^I add the user "([^"]*)"$/) do |user|
  step %{I initiate adding a user}
  step %{I enter the user "#{user}"}
  page.find('.flyout .primary-button', text: /\A#{Regexp.quote(I18n.t('admin.features.confirmations.add_user.accept'))}\z/i, exact: true, visible: true).click
end

Then(/^I see "([^"]*)" in the enabled user list$/) do |user|
  page.assert_selector('.admin-feature-edit table:last-of-type td', text: user)
end

When(/^I enter the user "([^"]*)"$/) do |user|
  page.fill_in(:username, with: user)
end

When(/^I do not see "([^"]*)" in the enabled user list$/) do |user|
  page.assert_no_selector('.admin-feature-edit table:last-of-type td', text: user)
end

Given(/^the feature "([^"]*)" is conditionally enabled for the "([^"]*)" user$/) do |feature_name, user|
  feature = Rails.application.flipper[feature_name]
  feature.enable_actor(User.find_or_create_if_valid_login(username: user))
end

Then(/^I see a remove user button$/) do
  page.assert_selector('.admin-feature-edit table:last-of-type .admin-feature-link-remove', visible: true)
end

When(/^I remove the user "([^"]*)"$/) do |user|
  row = page.find('.admin-feature-edit table:last-of-type td', text: user)
  row.find('.admin-feature-link-remove').click
end

When(/^the "(.*?)" page has been disabled$/) do |page|
  flags = case page
    when 'Manage Advances'
      { AdvancesController => ReportsController::MANAGE_ADVANCES_WEB_FLAGS }
    when 'Manage Letters of Credit'
      { LettersOfCreditController => ReportsController::MANAGE_LCS_WEB_FLAGS }
    when 'Manage Securities'
      { SecuritiesController => ReportsController::MANAGE_SECURITIES_WEB_FLAGS }
  end
  allow_any_instance_of(flags.keys[0]).to receive(:report_disabled?).with(flags.values[0]).and_return(true)
end

Then(/^I should see an empty data table with "(.*?)" messaging$/) do |messaging|
  searchText = case messaging
    when 'Data Currently Disabled'
      I18n.t('errors.table_data_unavailable')
    when 'No Records Returned'
      I18n.t('errors.table_data_no_records')
  end
  page.assert_selector('.report-table tbody tr:first-child .dataTables_empty', text: searchText)
end