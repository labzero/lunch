Then(/^I should see the securities flyout$/) do
  page.assert_selector('.nav-securities-flyout', visible: true)
end

Then(/^I should not see the securities flyout$/) do
  page.assert_no_selector('.flyout .nav-securities-flyout')
end

When(/^I cancel the Securities flyout$/) do
  page.find('a.secondary-button', text: I18n.t('global.cancel').upcase, exact: true, visible: true).click
end

When(/^I continue the Securities flyout$/) do
  page.find('a.primary-button', text: I18n.t('global.continue').upcase, exact: true, visible: true).click
end