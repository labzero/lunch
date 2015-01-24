Given(/^I am logged in as "(.*?)" with password "(.*?)"$/) do |user, password|
  step %{I am logged out}
  fill_in('user[username]', with: user)
  fill_in('user[password]', with: password)
  click_button(I18n.t('global.login'))
end

When(/^I log in as "(.*?)" with password "(.*?)"$/) do |user, password|
  step %{I am logged in as "#{user}" with password "#{password}"}
end

Given(/^I am logged out$/) do
  visit('/')
  begin
    page.find_field('user[username]', wait: 5 )
  rescue Capybara::ElementNotFound => e
    step %{I log out}
  end
end

When(/^I log out$/) do
  click_link(I18n.t('nav.primary.logout'))
end

Then(/^I should see the login form$/) do
  page.assert_selector("form.new_user input[type=submit][value='#{I18n.t('global.login')}']", visible: true)
end

Then(/^I should see a bad login error$/) do
  page.assert_selector('form.new_user .form-error', visible: true, text: I18n.t('devise.failure.invalid'))
end