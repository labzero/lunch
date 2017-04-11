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