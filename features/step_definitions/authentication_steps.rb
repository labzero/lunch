Given(/^I am logged in as "(.*?)" with password "(.*?)"$/) do |user, password|
  visit('/')
  fill_in('user[username]', with: user)
  fill_in('user[password]', with: password)
  click_button(I18n.t('global.login'))
end
