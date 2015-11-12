Then(/^I should see the fee schedules page$/) do
  page.assert_selector('h1', exact: true, visible: true, text: I18n.t('resources.fee_schedules.title'))
end