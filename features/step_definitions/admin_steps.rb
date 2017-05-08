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

Then(/^the (term rules|add advance availability) (daily limits|status|by term|by member|rate bands|rate report|term details) tab should be active$/) do |page_selector, active_nav|
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

When(/^I click on the (term rules|add advance availability) (daily limits|status|by term|by member|rate bands|rate report|term details) tab$/) do |page_selector, active_nav|
  page_selector = case page_selector
  when 'term rules'
    '.term-rules'
  when 'add advance availability'
    '.advance-availability'
  end
  nav_text = translate_tab_title(active_nav)
  page.find("#{page_selector} .tabbed-content nav a", text: nav_text, exact: true).click
end

When(/^I select (enabled|disabled|all) from the filter dropdown$/) do |filter|
  page.find('.advance-availability-member .dropdown').click
  page.find('.advance-availability-member .dropdown li', text: filter_to_text(filter), exact: true).click
end

Then(/^I should see (enabled|disabled|all) members in the table$/) do |filter|
  case filter
  when 'enabled'
    page.assert_selector('.advance-availability-member .report-table tr td input[checked]', visible: :visible)
    page.assert_no_selector('.advance-availability-member .report-table tr td input:not([checked])', visible: :visible)
  when 'disabled'
    page.assert_no_selector('.advance-availability-member .report-table tr td input[checked]', visible: :visible)
    page.assert_selector('.advance-availability-member .report-table tr td input:not([checked])', visible: :visible)
  when 'all'
    page.assert_no_selector('.advance-availability-member .report-table tr td input[type=checkbox]', visible: :hidden)
 end
end

Then(/^I should see the (?:term rules|advance availability) (limits|rate bands|by term) page in its (view-only|editable) mode$/) do |form, mode|
  selector = case form
  when 'limits'
    '.rules-limits-form'
  when 'rate bands'
    '.rules-rate-bands-form'
  when 'by term'
    '.rules-availability-by-term-form'
  end
  if mode == 'view-only'
    page.assert_no_selector("#{selector} input[type=submit]")
  else
    expect(page.all("#{selector} input[type=submit]").first.value).to eq(I18n.t('admin.term_rules.save'))
  end
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

When(/^I press the button to (check|uncheck) all checkboxes for the availability by term (form|vrc section|frc short section|frc long section)$/) do |status, section|
  action = status == 'check' ? 'checked' : 'unchecked'
  parent_selector = get_availability_by_term_selector(section)
  page.find("#{parent_selector} button[data-select-checkboxes-status='#{action}']").click
end

Then(/^I should see only (checked|unchecked) checkboxes for the availability by term (form|vrc section|frc short section|frc long section)/) do |status, section|
  expectation = status == 'checked' ? :to : :not_to
  parent_selector = get_availability_by_term_selector(section, true)
  checkboxes = page.all("#{parent_selector} input[type=checkbox]")
  checkboxes.each do |checkbox|
    expect(checkbox).send(expectation, be_checked)
  end
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
  when 'rate report'
    I18n.t('admin.term_rules.nav.rate_report')
  when 'term details'
      I18n.t('admin.term_rules.nav.term_details')
  end
end

def get_availability_by_term_selector(description, find_form=nil)
  case description
  when 'form'
    find_form ? '.rules-availability-by-term-form' : '.availability-by-term-form-actions:first-of-type'
  when 'vrc section'
    '.rules-availability-by-term-vrc'
  when 'frc short section'
    '.rules-availability-by-term-frc-short'
  when 'frc long section'
    '.rules-availability-by-term-frc-long'
  end
end

def filter_to_text(filter)
  case filter
  when 'all'
    I18n.t('admin.advance_availability.availability_by_member.filter.all')
  when 'enabled'
    I18n.t('admin.advance_availability.availability_by_member.filter.enabled')
  when 'disabled'
    I18n.t('admin.advance_availability.availability_by_member.filter.disabled')
  end
end