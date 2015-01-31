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

Then(/^I should only see "(.*?)" messages$/) do |text|
  category = case text
    when I18n.t('messages.categories.investor_relations')
      'investor_relations'
    when I18n.t('messages.categories.credit')
      'credit'
    when I18n.t('messages.categories.misc')
      'misc'
     when I18n.t('messages.categories.products')
       'products'
     when I18n.t('messages.categories.community')
       'community'
     when I18n.t('messages.categories.technical_updates')
       'technical_updates'
     else
       raise 'unknown category for corporate communication selection'
  end
  page.all('table tr').each do |row|
    expect(row['data-category']).to eq(category)
  end
end

When(/^I select the first message on the messages page$/) do
  page.find('table.corporate-communications-index tr:first-child').click
end

Then(/^I should be see the message detail view$/) do
  page.assert_selector('.corporate-communication-detail-actions')
  page.assert_selector('.corporate-communication-detail-intro')
  page.assert_selector('.corporate-communication-detail-reset')
end