Given(/^I am on the Messages page$/) do
  visit '/corporate_communications/all'
end

When(/^I click on the messages icon in the header$/) do
  page.find('.main-nav a.icon-announcements-after').click
end

Then(/^I should see a list of message categories in the sidebar$/) do
  [I18n.t('settings.email.all.title'), I18n.t('settings.email.community_program.title'),  I18n.t('settings.email.community_works.title'), I18n.t('settings.email.collateral.title'), I18n.t('settings.email.investor_relations.title'), I18n.t('settings.email.accounting.title'), I18n.t('settings.email.educational.title'), I18n.t('settings.email.products.title')].each do |category|
    page.assert_selector('.sidebar a', text: category)
  end
end

Then(/^I should see "(.*?)" as the page's title$/) do |text|
  page.assert_selector('h1', text: text)
end

When(/^I select the "(.*?)" filter in the sidebar$/) do |text|
  page.find('.sidebar-filter a', text: text).click
end

Then(/^I should see the active state for the "(.*?)" sidebar item$/) do |text|
  page.assert_selector('.sidebar-filter a.active', text: text)
end

When(/^I select the first message on the messages page$/) do
  page.find('table.corporate-communications-index tr:first-child').click
end

Then(/^I should be see the message detail view$/) do
  page.assert_selector('.corporate-communication-detail-actions')
  page.assert_selector('.corporate-communication-detail-intro')
  page.assert_selector('.corporate-communication-detail-reset')
end

When(/^I click on the "(.*?)" link at the top of the message detail view$/) do |text|
  page.find('.corporate-communication-detail-navigation a', text: text.upcase).click
end

Then(/^I should see a No Messages indicator$/) do
  page.assert_selector('.corporate-communications-empty tbody tr:first-child .dataTables_empty', text: I18n.t('errors.no_messages'))
end

Then(/^"(.*?)" category should be disabled$/) do |text|
  page.assert_selector('.corporate-communications .sidebar-filter span.disabled', text: text)
end

When(/^the "(.*?)" category has no messages$/) do |text|
  pending
  # placeholder step for now in case we implement removing messages during testing
end

Given(/^I remember all the message titles$/) do
  @messages = page.all('.corporate-communications-index h3').collect(&:text)
end

Then(/^I see the title of the second message$/) do
  expect(page.find('.corporate-communication-detail-intro h2').text).to eq(@messages.second)
end

Then(/^I see the title of the first message$/) do
  expect(page.find('.corporate-communication-detail-intro h2').text).to eq(@messages.first)
end

When(/^I click on a message with attachments$/) do
  page.all('.corporate-communications-index a.icon-paperclip-before', visible: true).first.click
end

Then(/^I should see a list of attachments$/) do
  page.assert_selector('.corporate-communication-attachments ul li', minimum: 1, visible: true)
end