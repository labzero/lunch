Given(/^I fill in and submit the login form with username "(.*?)" and password "(.*?)"$/) do |user, password|
  fill_in('user[username]', with: user)
  fill_in('user[password]', with: password)
  click_button(I18n.t('global.login'))
end

Given(/^I fill in and submit the login form$/) do
  step %{I fill in and submit the login form with username "#{extranet_user['username']}" and password "#{extranet_user['password']}"}
end

Given(/^I fill in and submit the login form with a user not associated with a bank$/) do
  step %{I fill in and submit the login form with username "#{primary_user['username']}" and password "#{primary_user['password']}"}
end

Given(/^I am logged in as "(.*?)" with password "(.*?)"$/) do |user, password|
  step %{I am logged out}
  step %{I fill in and submit the login form with username "#{user}" and password "#{password}"}
end

Given(/^I am logged in$/) do
  step %{I am logged in as an "extranet user"}
end

Given(/^I am logged in as an? "(.*?)"$/) do |user_type|
  user = case user_type
    when 'primary user'
      primary_user
    when 'quick-advance signer'
      quick_advance_signer
    when 'quick-advance non-signer'
      quick_advance_non_signer
    when 'access manager'
      access_manager
    when 'extranet user'
      extranet_user
    when 'deletable user'
      deletable_user
    else
      raise 'unknown user type'
  end

  step %{I am logged in as "#{user['username']}" with password "#{user['password']}"}
  needs_member = page.has_css?('.welcome legend', text: I18n.t('welcome.choose_member'), wait: 5) rescue Capybara::ElementNotFound
  step %{I select the "#{CustomConfig.env_config['primary_bank']}" member bank} if needs_member
  page.assert_selector('.main-nav .nav-logout')
end

When(/^I log in$/) do
  step %{I log in as an "extranet user"}
end

When(/^I log in as (?:a|an) "(.*?)"$/) do |user_type|
  user = case user_type
    when 'primary user'
      primary_user
    when 'extranet user'
      extranet_user
    else
      raise 'unknown user type'
  end

  step %{I log in as "#{user['username']}" with password "#{user['password']}"}
  needs_member = page.has_css?('.welcome legend', text: I18n.t('welcome.choose_member'), wait: 5) rescue Capybara::ElementNotFound
  step %{I select the "#{CustomConfig.env_config['primary_bank']}" member bank} if needs_member
end

When(/^I log in as "(.*?)" with password "(.*?)"$/) do |user, password|
  step %{I am logged out}
  step %{I fill in and submit the login form with username "#{user}" and password "#{password}"}
end

When(/^I select the (\d+)(?:st|rd|th) member bank$/) do |num|
  dropdown = page.find('.welcome .dropdown')
  dropdown.click
  dropdown.find("li:nth-child(#{num.to_i})").click
  click_button(I18n.t('global.continue'))
end

When(/^I select the "(.*?)" member bank$/) do |bank_name|
  # remove the rack_test branch once we have users tied to a specific bank
  if Capybara.current_driver == :rack_test
    page.find('.welcome .dropdown option', text: bank_name).select_option
    form = page.find('.welcome form')
    class << form
      def submit
        Capybara::RackTest::Form.new(self.driver, self.native).submit({})
      end
    end
    form.submit
  else
    dropdown = page.find('.welcome .dropdown')
    dropdown.click
    dropdown.find('li', text: bank_name).click
    click_button(I18n.t('global.continue'))
  end
end

Given(/^I am logged out$/) do
  visit('/')
  begin
    page.find_field('user[username]', wait: 5)
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

Then(/^I should see the member bank selector$/) do
  page.assert_selector('.welcome .dropdown-selection', text: I18n.t('welcome.select_bank'))
end

Then(/^I should see the member bank selector submit button disabled$/) do
  page.assert_selector(".welcome form input[type=submit][disabled][value=#{I18n.t('global.continue')}]")
end

Then(/^I should be logged out$/) do
  step %{I should see the login form}
  step %{I visit the dashboard}
  step %{I should see the login form}
end

Then(/^I should see the name for the "(.*?)" in the header$/) do |user_type|
  page.assert_selector('.main-nav li', text: user_type['given_name'])
end

def primary_user
  CustomConfig.env_config['primary_user']
end

def quick_advance_signer
  CustomConfig.env_config['signer_advances_user']
end

def quick_advance_non_signer
  CustomConfig.env_config['non_signer_advances_user']
end

def extranet_user
  CustomConfig.env_config['extranet_user']
end

def access_manager
  CustomConfig.env_config['access_manager']
end

def deletable_user
  CustomConfig.env_config['deletable']
end