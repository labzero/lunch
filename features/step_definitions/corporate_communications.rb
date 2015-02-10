Given(/^I am on the Messages Page$/) do
  visit '/corporate_communications/all'
end

When(/^I click on the messages icon in the header$/) do
  page.find('.main-nav a.icon-envelope-after').click
end

Then(/^I should see a list of message categories in the sidebar$/) do
  [I18n.t('messages.categories.all'), I18n.t('messages.categories.community'), I18n.t('messages.categories.credit'), I18n.t('messages.categories.investor_relations'), I18n.t('messages.categories.misc'), I18n.t('messages.categories.technical_updates'), I18n.t('messages.categories.products')].each do |category|
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

Then(/^I should remember the date of that message and its title$/) do
  @message_detail_date = page.find('.corporate-communication-detail-intro p').text
  @message_detail_title = page.find('.corporate-communication-detail-intro h2').text
end

Then(/^the date of the current message should be earlier than the date of the message I remembered and the title should be different$/) do
  expect(page.find('.corporate-communication-detail-intro p').text.to_date).to be < @message_detail_date.to_date
  expect(page.find('.corporate-communication-detail-intro h2').text).to_not eq(@message_detail_title)
end

Then(/^I should see the date and the title of the message I remembered$/) do
  expect(page.find('.corporate-communication-detail-intro p').text).to eq(@message_detail_date)
  expect(page.find('.corporate-communication-detail-intro h2').text).to eq(@message_detail_title)
end

When(/^I click on the "(.*?)" link at the top of the message detail view$/) do |text|
  page.find('.corporate-communication-detail-navigation a', text: text.upcase).click
end