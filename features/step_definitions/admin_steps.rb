When(/^I visit the admin dashboard$/) do
  visit('/admin')
end

Then(/^I see the admin dashboard$/) do
  page.assert_selector('.admin header h1', text: I18n.t('admin.title'), exact: true)
end

Then(/^I should be on the term rules (limits) page$/) do |rules_page|
  title = case rules_page
  when 'limits'
    I18n.t('admin.term_rules.title')
  end
  page.assert_selector('.term-rules h1', text: title, exact: true)
end

Then(/^the term rules (daily limits) tab should be active/) do |active_nav|
  nav_text = case active_nav
  when 'daily limits'
    I18n.t('admin.term_rules.nav.daily_limit')
  end
  page.assert_selector('.limits .tabbed-content nav a', text: nav_text, exact: true)
end

Then(/^I should see the term rules limits page in view-only mode$/) do
  page.assert_no_selector('.rules-limits-form input[type=submit]')
end

Then(/^I should see the term rules limits page in its editable mode$/) do
  expect(page.find('.rules-limits-form input[type=submit]').value).to eq(I18n.t('admin.term_rules.save'))
end

When(/^I am on the term rules (limits) page$/) do |rules_page|
  step %{I am logged into the admin panel}
  case rules_page
  when 'limits'
    step 'I click on the trade credit rules link in the header'
    step 'I click on the term rules link in the header'
    step 'I should be on the term rules limits page'
  end
end

When(/^I click the save changes button for the rules limits form$/) do
  page.assert_selector('.rules-limits-form input[type=submit]')
  page.find('.rules-limits-form input[type=submit]').click
end

Then(/^I should see the success message on the term rules limits page$/) do
  page.assert_selector('.term-rules .form-success-section p', text: I18n.t('admin.term_rules.messages.success'), exact: true)
end