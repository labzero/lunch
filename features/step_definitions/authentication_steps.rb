Given(/^I am logged in as "(.*?)" with password "(.*?)"$/) do |user, password|
  step %{I am logged out}
  fill_in('user[username]', with: user)
  fill_in('user[password]', with: password)
  click_button(I18n.t('global.login'))
end

Given(/^I am logged in$/) do
  step %{I am logged in as "#{primary_user['username']}" with password "#{primary_user['password']}"}
end

When(/^I log in$/) do
  step %{I log in as "#{primary_user['username']}" with password "#{primary_user['password']}"}
end

When(/^I log in as "(.*?)" with password "(.*?)"$/) do |user, password|
  step %{I am logged in as "#{user}" with password "#{password}"}
end

Given(/^I am logged out$/) do
  visit('/')
  begin
    page.find_field('user[username]', wait: 2 )
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

When(/^I log in with a bad password$/) do
  step %{I log in as "#{primary_user['username']}" with password "badpassword"}
end

When(/^I log in with a bad username$/) do
  step %{I log in as "badusername" with password "#{primary_user['password']}"}
end

def primary_user
  CustomConfig.env_config['primary_user']
end