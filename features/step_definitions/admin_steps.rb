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

Then(/^the (term rules|add advance availability) (daily limits|status|by term|by member|rate bands) tab should be active$/) do |page_selector, active_nav|
  page_selector = case page_selector
  when 'term rules'
    '.term-rules'
  when 'add advance availability'
    '.advance-availability'
  end
  nav_text = translate_tab_title(active_nav)
  page.assert_selector("#{page_selector} .tabbed-content nav .active-tab", text: nav_text, exact: true)
end

Then(/^I should be on the add advance availability (status|by term|by member) page$/) do |availability_page|
  selector = case availability_page
  when 'status'
    '.advance-availability-status'
  when 'by term'
    '.advance-availability-term'
  when 'by member'
    '.advance-availability-member'
  end
  page.assert_selector(selector)
end

When(/^I click on the (term rules|add advance availability) (daily limits|status|by term|by member|rate bands) tab$/) do |page_selector, active_nav|
  page_selector = case page_selector
  when 'term rules'
    '.term-rules'
  when 'add advance availability'
    '.advance-availability'
  end
  nav_text = translate_tab_title(active_nav)
  page.find("#{page_selector} .tabbed-content nav a", text: nav_text, exact: true).click
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

def translate_tab_title(nav)
  case nav
  when 'daily limits'
    I18n.t('admin.term_rules.nav.daily_limit')
  when 'status'
    I18n.t('admin.advance_availability.nav.status')
  when 'by term'
    I18n.t('admin.advance_availability.nav.term')
  when 'by member'
    I18n.t('admin.advance_availability.nav.member')
  when 'rate bands'
    I18n.t('admin.term_rules.nav.rate_bands')
  end
end