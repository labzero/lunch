When(/^I click on the privacy policy link in the footer$/) do |link|
  click_link(I18n.t("global.privacy_policy"))
end

Then(/^I should see "(.*?)" as the page's title$/) do |text|
  page.assert_selector('h1', text: 'Privacy Policy')
end
