Given(/^I fill in and submit the login form with username "(.*?)" and password "(.*?)"$/) do |user, password|
  fill_in('user[username]', with: user)
  fill_in('user[password]', with: password)

  @login_flag = flag_page
  click_button(I18n.t('global.login'))
  wait_for_unflagged_page(@login_flag)
  terms_accepted = page.has_no_css?('.terms-row h1', text: I18n.t('terms.title'), wait: 0)
  step %{I accept the Terms of Use} unless terms_accepted
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
  select_member_if_needed
  page.assert_selector('.main-nav .nav-logout')
end

Then(/^I should see the Terms of Use page$/) do
  page.assert_selector('.terms-row h1', text: I18n.t('terms.title'))
end

When (/^I accept the Terms of Use$/) do
  @login_flag = flag_page
  page.find(".primary-button[value=\'#{I18n.t('terms.agree')}\']").click
end

When(/^I log in$/) do
  step %{I log in as an "extranet user"}
end

When(/^I fill in and submit the login form with a first-time user$/) do
  # implement way of simulating first-time user to test Terms of Service flow
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
  # needs_to_accept_terms = page.has_css?('.terms-row h1', text: I18n.t('terms.title'), wait: 5) rescue Capybara::ElementNotFound
  # step %{I accept the Terms of Use} if needs_to_accept_terms
  select_member_if_needed
end

When(/^I log in as "(.*?)" with password "(.*?)"$/) do |user, password|
  step %{I am logged out}
  step %{I fill in and submit the login form with username "#{user}" and password "#{password}"}
end

When(/^I select the (\d+)(?:st|rd|th) member bank$/) do |num|
  @login_flag = flag_page
  dropdown = page.find('select[name=member_id]')
  dropdown.click
  dropdown.find("option:nth-child(#{num.to_i})").click
  click_button(I18n.t('global.continue'))
end

When(/^I select the "(.*?)" member bank$/) do |bank_name|
  # remove the rack_test branch once we have users tied to a specific bank
  @login_flag = flag_page
  if Capybara.current_driver == :rack_test
    page.find('select[name=member_id] option', text: bank_name).select_option
    form = page.find('.welcome form')
    class << form
      def submit
        Capybara::RackTest::Form.new(self.driver, self.native).submit({})
      end
    end
    form.submit
  else
    dropdown = page.find('select[name=member_id]')
    dropdown.click
    dropdown.find('option', text: bank_name).click
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
  page.assert_selector("form.welcome-login input[type=submit][value='#{I18n.t('global.login')}']", visible: true)
end

Then(/^I should see a bad login error$/) do
  page.assert_selector('form.welcome-login .form-error', visible: true, text: I18n.t('devise.failure.invalid'))
end

When(/^I log in with a bad password$/) do
  step %{I log in as "#{primary_user['username']}" with password "badpassword"}
end

When(/^I log in with a bad username$/) do
  step %{I log in as "badusername" with password "#{primary_user['password']}"}
end

Then(/^I should see the member bank selector$/) do
  page.assert_selector('select[name=member_id]', text: I18n.t('welcome.select_bank'))
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

def select_member_if_needed
  wait_for_unflagged_page(@login_flag)
  has_member = page.has_no_css?('.welcome legend', text: I18n.t('welcome.choose_member'), wait: 0)
  step %{I select the "#{CustomConfig.env_config['primary_bank']}" member bank} unless has_member
end

# def missing_element_on_load?(query, options={}, timeout=5, &load_block)
#   flag = flag_page
#   load_block.call
#   timeout_at = Time.zone.now + timeout
#   while Time.zone.now < timeout_at
#     break unless page_is_flagged?(flag)
#   end
#   page.has_no_css?(query, options.merge(wait: 1))
# end

def flag_page
  flag = SecureRandom.hex
  page.execute_script("#{page_flag_var(flag)} = true;")
  flag
end

def page_is_flagged?(flag)
  page.evaluate_script(page_flag_var(flag))
end

def page_flag_var(flag)
  "window.capybara_flag_#{flag}"
end

# returns true if an unflagged version of the page was found before the timeout, raises a ExpectationNotMet otherwise
def wait_for_unflagged_page(flag, timeout=5)
  timeout_at = Time.zone.now + timeout
  while Time.zone.now < timeout_at
    return true unless page_is_flagged?(flag)
  end

  raise Capybara::ExpectationNotMet.new("#{flag} was still on page after #{timeout} seconds.")
end
