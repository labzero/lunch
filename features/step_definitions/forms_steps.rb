Then(/^I should see the forms page$/) do
  page.assert_selector('.resource-forms-page')
end

Given(/^I am on the forms page$/) do
  visit '/resources/forms'
end

Then(/^I should see the forms page focused on the (agreements|authorizations|credit|collateral) topic$/) do |topic|
  page.assert_selector('.resource-forms-page')
  expect(current_url.ends_with?("##{topic}")).to eq(true)
end

Then(/^I should see at least one form to download$/) do
  page.assert_selector('.resource-form-table a', text: /\A#{Regexp.quote(I18n.t('global.view_pdf'))}\z/i, minimum: 1)
end

When(/^I click on the (agreements|authorizations|credit|collateral) link in the ToC$/) do |topic|
  click_link(I18n.t("resources.forms.#{topic}.title"))
end

Then(/^I should see "([^"]*)" link$/) do |arg1|
  page.assert_selector('.resource-form-table a', text: /\A#{Regexp.quote(I18n.t('global.sign'))}\z/i, minimum: 1)
end

When(/^I click on the sign link$/) do
  click_link(I18n.t('global.sign'))
end
