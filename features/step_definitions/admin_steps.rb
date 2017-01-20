When(/^I visit the admin dashboard$/) do
  visit('/admin')
end

Then(/^I see the admin dashboard$/) do
  page.assert_selector('.admin header h1', text: I18n.t('admin.title'), exact: true)
end