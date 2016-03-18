Given(/^I fill in and submit the login form with username "(.*?)" and password "(.*?)"$/) do |user, password|
  step %{I fill in and submit the login form with username "#{user}" and password "#{password}" ignoring the terms of use}

  accept_terms_if_needed
end

Given(/^I fill in and submit the login form with username "(.*?)" and password "(.*?)" ignoring the terms of use$/) do |user, password|
  fill_in('user[username]', with: user)
  fill_in('user[password]', with: password)

  @login_flag = flag_page
  click_button(I18n.t('global.login'))
  wait_for_unflagged_page(@login_flag)

  session_id = get_session_id
  Cucumber.logger.info("Session ID: #{session_id}\n") if session_id
end

Given(/^I fill in and submit the login form$/) do
  step %{I fill in and submit the login form with username "#{extranet_user['username']}" and password "#{extranet_user['password']}"}
end

Given(/^I fill in and submit the login form with a user not associated with a bank$/) do
  step %{I fill in and submit the login form with username "#{primary_user['username']}" and password "#{primary_user['password']}"}
end

Given(/^I am logged in as "(.*?)" with password "(.*?)"$/) do |user, password|
  step %{I am logged out}
  step %{I visit the root path}
  step %{I fill in and submit the login form with username "#{user}" and password "#{password}"}
end

Given(/^I am logged in$/) do
  step %{I am logged in as an "extranet user"}
end

Given(/^I am logged in to a bank with data for the "([^"]*)" report$/) do |report|
  user_type = case report
  when 'Securities Services Monthly Statement'
    'intranet user'
  else
    'extranet user'
  end

  step %{I am logged in as a "#{user_type}"}
end

Given(/^I am logged in as an? "(.*?)"$/) do |user_type|
  user = user_for_type(user_type)

  step %{I am logged in as "#{user['username']}" with password "#{user['password']}"}
  select_member_if_needed(user['bank'])
  page.assert_selector('.main-nav .nav-logout')
end

Then(/^I should see the Terms of Use page$/) do
  page.assert_selector('.terms-row h1', text: I18n.t('terms.title'))
end

When(/^I (accept|do not accept) the Terms of Use$/) do |button|
  @login_flag = flag_page
  if button == 'accept'
    page.find(".primary-button[value=\'#{I18n.t('terms.agree')}\']").click
  else
    page.find(".secondary-button", text: /#{Regexp.quote(I18n.t('terms.cancel'))}/i).click
  end
  wait_for_unflagged_page(@login_flag)
end

When(/^I log in$/) do
  step %{I log in as an "extranet user"}
end

When(/^I fill in and submit the login form with a first-time user$/) do
  step %{I fill in and submit the login form with username "#{first_time_user['username']}" and password "#{first_time_user['password']}" ignoring the terms of use}
end

When(/^I fill in and submit the login form with the capitalized last user$/) do
  step %{I fill in and submit the login form with username "#{first_time_user['username'].upcase}" and password "#{first_time_user['password']}" ignoring the terms of use}
end

When(/^I fill in and submit the login form with an? (expired user|extranet no role user|primary user|offsite user)$/) do |user_type|
  user = user_for_type(user_type)
  step %{I fill in and submit the login form with username "#{user['username']}" and password "#{user['password']}"}
end

When(/^I log in as (?:a|an) "(.*?)"$/) do |user_type|
  user = user_for_type(user_type)
  step %{I log in as "#{user['username']}" with password "#{user['password']}"}
  select_member_if_needed(user['bank'])
end

When(/^I log in as "(.*?)" with password "(.*?)"$/) do |user, password|
  step %{I am logged out}
  step %{I visit the root path}
  step %{I fill in and submit the login form with username "#{user}" and password "#{password}"}
end

When(/^I login as the (password change user|expired user) with the new password$/) do |user_type|
  user = user_for_type(user_type)
  step %{I log in as "#{user['username']}" with password "#{valid_password}"}
  select_member_if_needed(user['bank'])
end

When(/^I select the (\d+)(?:st|rd|th) member bank$/) do |num|
  @login_flag = flag_page
  dropdown = page.find('select[name=member_id]')
  dropdown.click
  option = dropdown.find("option:nth-child(#{num.to_i+1})")
  @member_id = option.value
  option.click
  click_button(I18n.t('global.continue'))
end

When(/^I select the "(.*?)" member bank$/) do |bank_name|
  # remove the rack_test branch once we have users tied to a specific bank
  @login_flag = flag_page
  @member_name = bank_name
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
    option = dropdown.find('option', text: /\A#{Regexp.quote(bank_name)}\z/)
    @member_id = option.value
    option.click
    click_button(I18n.t('global.continue'))
  end
end

Given(/^I am logged in to a bank with Quick Reports$/) do
  step %{I am logged in as a "intranet user"}
  MemberProcessQuickReportsJob.perform_now(current_member_id, QuickReportSet.current_period)
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
  step %{I should see the logged out page}
end

Then(/^I should see the login form$/) do
  page.assert_selector("form.welcome-login input[type=submit][value='#{I18n.t('global.login')}']", visible: true)
end

Then(/^I should see the logged out page/) do
  page.assert_selector('.welcome-logged-out')
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
  step %{I should see the logged out page}
  step %{I visit the dashboard}
  step %{I should see the login form}
end

Then(/^I should see the name for the "(.*?)" in the header$/) do |user_type|
  page.assert_selector('.main-nav li', text: user_type['given_name'])
end

Then(/^I should be logged in$/) do
  wait_for_unflagged_page(@login_flag)
  step %{I visit the dashboard}
  step %{I should see dashboard modules}
end

Then(/^I should see the change password form$/) do
  page.assert_selector('form legend', exact: true, visible: true, text: I18n.t('settings.change_password.title'))
  page.assert_selector('form p', exact: true, visible: true, text: I18n.t('settings.change_password.instructions'))
end


Then(/^I should see the change password success page$/) do
  page.assert_selector('.welcome .password-change-success')
end

Then(/^I should see password change validations$/) do
  step %{I enter a password of "abcder12"}
  step %{I should see a criteria not met required password error}
  step %{I enter a password of "abcder!"}
  step %{I should see a criteria not met required password error}
  step %{I enter a password of "abcderABC"}
  step %{I should see a criteria not met required password error}
  step %{I enter a password of "ABCDE@#!"}
  step %{I should see a criteria not met required password error}
  step %{I enter a password of "ABC83429"}
  step %{I should see a criteria not met required password error}
  step %{I enter a password of "9467@#!**"}
  step %{I should see a criteria not met required password error}
  step %{I enter a password of "123Cd3!"}
  step %{I should see a minimum length required password error}
  step %{I enter a password of "123Abcd3!"}
  step %{I enter a password confirmation of "123Abcd3!"}
  step %{I should see no password errors}
end

When(/^I enter a valid new password$/) do
  step %{I enter a password of "#{valid_password}"}
  step %{I enter a password confirmation of "#{valid_password}"}
end

When(/^I enter a new valid password in the first field$/) do
  step %{I enter a password of "#{valid_password}"}
end

When(/^I enter a new valid password in the password confirmation field$/) do
  step %{I enter a password confirmation of "#{valid_password}"}
end

When(/^I focus on the password confirmation field$/) do
  page.find('#user_password_confirmation').click
end

When(/^I focus on the new password field$/) do
  page.find('#user_password').click
end

Then(/^I should not see a password match error$/) do
  page.assert_no_selector('.label-error', text: I18n.t('activerecord.errors.models.user.attributes.password.confirmation'), exact: true)
end

Then(/^I should see a password match error$/) do
  page.assert_selector('.label-error', text: I18n.t('activerecord.errors.models.user.attributes.password.confirmation'), exact: true)
end

When(/^I try to submit the form$/) do
  page.find('form input[type=submit]').click
end

When(/^I dismiss the change password success page$/) do
  @login_flag = flag_page
  click_link(I18n.t('global.continue'))
end

Then(/^I proceed through the login flow$/) do
  accept_terms_if_needed
  select_member_if_needed
end

When(/^I fill in and submit the login form with an expired user and the new password$/) do
  step %{I fill in and submit the login form with username "#{expired_user['username']}" and password "#{valid_password}"}
end

When(/^I visit the logged out page$/) do
  visit '/logged-out'
end

When(/^I am signed in as a Chaste Manhattan user$/) do
  step 'I am logged out'
  step 'I visit the dashboard'
  step 'I fill in and submit the login form with username "extra-chaste" and password "development"'
end

def user_for_type(user_type)
  case user_type
  when 'primary user'
    primary_user
  when 'intranet user'
    intranet_user
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
  when 'password change user'
    password_changable_user
  when 'expired user'
    expired_user
  when 'extranet no role user'
    extranet_no_role_user
  when 'offsite user'
    offsite_user
  when 'user with disabled quick advances'
    advances_disabled_user
  else
    raise 'unknown user type'
  end
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

def intranet_user
  CustomConfig.env_config['intranet_user']
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

def resetable_user
  CustomConfig.env_config['resetable']
end

def expired_user
  CustomConfig.env_config['expired']
end

def valid_password
  CustomConfig.env_config['valid_password']
end

def password_changable_user
  CustomConfig.env_config['password_changable']
end

def extranet_no_role_user
  CustomConfig.env_config['extranet_no_role']
end

def offsite_user
  CustomConfig.env_config['offsite']
end

def advances_disabled_user
  CustomConfig.env_config['advances_disabled']
end

def first_time_user
  CustomConfig.env_config['first_time']
end

def current_member_name
  @member_name ||= CustomConfig.env_config['primary_user']['bank']
end

def current_member_id
  @member_id
end

def select_member_if_needed(bank=nil)
  bank ||= CustomConfig.env_config['primary_user']['bank']
  wait_for_unflagged_page(@login_flag)
  has_member = page.has_no_css?('.welcome legend', text: I18n.t('welcome.choose_member'), wait: 0)
  step %{I select the "#{bank}" member bank} unless has_member
end

def accept_terms_if_needed
  wait_for_unflagged_page(@login_flag)
  terms_accepted = page.has_no_css?('.terms-row h1', text: I18n.t('terms.title'), wait: 0)
  step %{I accept the Terms of Use} unless terms_accepted
end

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

def session_cookie_key
  if Rails && Rails.respond_to?(:application)
    Rails.application.config.session_options.fetch(:key)
  else
    ENV['CUCUMBER_SESSION_KEY'] || '_fhlb-member_session'
  end
end

def get_session_id
  key = session_cookie_key
  cookie = (page.driver.browser.manage.all_cookies.find {|cookie| cookie[:name] == key}) || {}
  cookie[:value]
end

def silent_class_reload(file)
  original_verbose, $VERBOSE = $VERBOSE, nil
  begin
    load file
  ensure
    $VERBOSE = original_verbose
  end
end


Around('@offsite-ip') do |scenario, block|
  old_env = ENV['FHLB_INTERNAL_IPS']
  begin
    ENV['FHLB_INTERNAL_IPS'] = ''
    silent_class_reload 'internal_user_policy.rb'
    block.call
  ensure
    ENV['FHLB_INTERNAL_IPS'] = old_env
    silent_class_reload 'internal_user_policy.rb'
  end
end

Around('@first-time-user') do |scenario, block|
  user = User.find_by(username: first_time_user['username'])
  user.delete if user
  block.call
end
