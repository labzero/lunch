When(/^I click on the Securities link in the header$/) do
  page.find('.secondary-nav a', text: I18n.t('securities.title'), exact: true).click
end

Then(/^I should be on the Manage Securities page$/) do
  page.assert_selector('h1', text: I18n.t('securities.manage.title'), exact: true)
  step 'I should see a report table with multiple data rows'
end