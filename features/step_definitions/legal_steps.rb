When(/^I visit the privacy policy page$/) do
  visit '/privacy-policy'
end

Then /^I see the privacy policy$/ do
  page.assert_selector('.privacy-policy-page h1', visible: true, text: I18n.t('global.privacy_policy'), exact: true)
end

When(/^I visit the terms of use page$/) do
  visit '/terms-of-use'
end

Then /^I see the terms of use$/ do
  page.assert_selector('.terms-of-use-page h1', visible: true, text: I18n.t('global.terms_of_use'), exact: true)
end

When(/^I visit the contact page$/) do
  visit '/contact'
end

Then /^I see the contact information for FHLB$/ do
  page.assert_selector('.contact-page h1', visible: true, text: I18n.t('global.contact'), exact: true)
end
