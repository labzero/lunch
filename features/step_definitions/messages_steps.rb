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