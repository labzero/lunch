When(/^I visit the privacy policy page$/) do
  visit '/privacy-policy'
end

Then /^I see the privacy policy$/ do
  page.assert_selector('.privacy-policy-page h1', visible: true, text: I18n.t('global.privacy_policy'), exact: true)
end
