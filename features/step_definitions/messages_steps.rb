Given(/^I am on the Messages Page$/) do
  visit '/messages'
end

When(/^I click on the messages icon in the header$/) do
  page.find('.main-nav a.icon-envelope-after').click
end

Then(/^I should see a list of message categories in the sidebar$/) do
  [I18n.t('messages.categories.all'), I18n.t('messages.categories.community'), I18n.t('messages.categories.credit'), I18n.t('messages.categories.investor_relations'), I18n.t('messages.categories.misc'), I18n.t('messages.categories.technical_updates'), I18n.t('messages.categories.products')].each do |category|
    page.assert_selector('.sidebar span', text: category)
  end
end

Then(/^I should see "(.*?)" as the page's title$/) do |text|
  page.assert_selector('h1', text: text)
end

When(/^I select the "(.*?)" filter in the sidebar$/) do |text|
  page.find('.sidebar-filter span', text: text).click
end

Then(/^I should see the active state for the "(.*?)" sidebar item$/) do |text|
  page.assert_selector('.sidebar-filter span.active', text: text)
end

Then(/^I should only see "(.*?)" messages$/) do |text|
  category = page.find('.sidebar-filter span', text: text)['data-sidebar-value']
  page.all('table tr').each do |row|
    expect(row['data-category']).to eq(category)
  end
end