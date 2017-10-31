When(/^I visit the admin dashboard$/) do
  visit('/admin')
end

When(/^I am on the data visibility web flags page$/) do
  visit('/admin/data-visibility/flags')
end

Then(/^I see the admin dashboard$/) do
  page.assert_selector('.admin header h1', text: I18n.t('admin.title'), exact: true)
end

Then(/^I should be on the (term rules limits|end of day shutoff|data visibility web flags|data and institution status) page$/) do |rules_page|
  title = case rules_page
  when 'term rules limits'
    I18n.t('admin.term_rules.title')
  when 'end of day shutoff'
    I18n.t('admin.shutoff_times.title')
  when 'data visibility web flags'
    I18n.t('admin.data_visibility.manage_data_visibility.title')
  when 'data and institution status'
    I18n.t('admin.data_visibility.status.title')
  end
  page.assert_selector('.admin h1', text: title, exact: true)
end

Then(/^I should see the data visibility web flags page in its (view-only|editable) mode$/) do |mode|
  selector = '.data-visibility-flags-form input[type=submit'
  mode == 'view-only' ? page.assert_no_selector(selector) : page.assert_selector(selector, visible: :visible)
end

Then(/^the (term rules|add advance availability|end of day shutoff) (daily limits|status|by term|by member|rate bands|rate report|term details|early shutoffs|typical shutoffs) tab should be active$/) do |rules_section, active_nav|
  page_selector = css_selector_from_rules_section(rules_section)
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

When(/^I click on the (term rules|add advance availability|end of day shutoff) (daily limits|status|by term|by member|rate bands|rate report|term details|typical shutoffs) tab$/) do |rules_section, active_nav|
  page_selector = css_selector_from_rules_section(rules_section)
  nav_text = translate_tab_title(active_nav)
  page.find("#{page_selector} .tabbed-content nav a", text: nav_text, exact: true).click
end

When(/^I select the (enabled|disabled|all) filter from the advance availability by member dropdown$/) do |filter|
  page.all('.advance-availability-member .dropdown').first.click
  page.all('.advance-availability-member .dropdown li', text: filter_to_text(filter), exact: true).first.click
end

Then(/^I should see (enabled|disabled|all) members in the advance availability by member table$/) do |filter|
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

Then(/^I should see the (?:term rules|advance availability|) (limits|rate bands|by term|by member) page in its (view-only|editable) mode$/) do |form, mode|
  selector = case form
  when 'limits'
    '.rules-limits-form'
  when 'rate bands'
    '.rules-rate-bands-form'
  when 'by term'
    '.rules-availability-by-term-form'
  when 'by member'
    '.rules-availability-by-member-form'
  end
  if mode == 'view-only'
    page.assert_no_selector("#{selector} input[type=submit]")
  else
    expect(page.all("#{selector} input[type=submit]").first.value).to eq(I18n.t('admin.term_rules.save'))
  end
end

Then(/^I should see the end of day shutoff early shutoffs page in its (view-only|editable) mode$/) do |mode|
  if mode == 'view-only'
    page.assert_no_selector('.advance-shutoff-times-early a', text: /\A#{I18n.t('admin.shutoff_times.actions.schedule_new')}\z/i)
    page.assert_no_selector('.advance-shutoff-times-early table th:nth-child(4)')
  else
    page.assert_selector('.advance-shutoff-times-early a', text: /\A#{I18n.t('admin.shutoff_times.actions.schedule_new')}\z/i)
    page.assert_selector('.advance-shutoff-times-early table th:nth-child(4)', text: I18n.t('global.actions'), exact: true)
  end
end

Then(/^I should see the end of day shutoff typical shutoffs page in its (view-only|editable) mode$/) do |mode|
  if mode == 'view-only'
    page.assert_no_selector('.rules-typical-shutoff-form')
    page.assert_selector('.advance-shutoff-times-typical table')
  else
    page.assert_selector('.rules-typical-shutoff-form')
    page.assert_no_selector('.advance-shutoff-times-typical table')
  end
end

Then(/^I should see the advance availabiltiy status page in its (view-only|editable) mode$/) do |mode|
  if mode == 'view-only'
    page.assert_no_selector('.advance-availability-status section:first-of-type a')
  else
    page.assert_selector('.advance-availability-status section:first-of-type a')
  end
end

When(/^I am on the term rules (limits) page$/) do |rules_page|
  step %{I am logged into the admin panel as an etransact admin}
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

Then(/^I should see the (success|error) message on the (?:term rules|advance availability|data visibility) (limits|by member|status|early shutoff|edit early shutoff|remove early shutoff|view early shutoff|typical shutoff|flags) page( for that member)?$/) do |result, form, member_present|
  parent_selector = case form
  when 'limits'
    '.term-rules'
  when 'by member'
    '.advance-availability-member'
  when 'status'
    '.advance-availability-status'
  when 'early shutoff'
    '.advance-shutoff-times-early'
  when 'view early shutoff'
    '.advance-shutoff-times-view-early'
  when 'typical shutoff'
    '.advance-shutoff-times-typical'
  when 'flags'
    '.data-visibility-flags'
  end
  success_message = case form
  when 'early shutoff'
    I18n.t('admin.shutoff_times.schedule_early.success')
  when 'edit early shutoff'
    I18n.t('admin.shutoff_times.schedule_early.update_success')
  when 'remove early shutoff'
    I18n.t('admin.shutoff_times.schedule_early.remove_success')
  else
    I18n.t('admin.term_rules.messages.success')
  end
  if result == 'success'
    page.assert_selector("#{parent_selector} .form-success-section p", text: success_message, exact: true)
  else
    page.assert_selector("#{parent_selector} .form-error-section p", text: I18n.t('admin.term_rules.messages.error'), exact: true)
  end
  expect(page.find('.data-visibility-select-member select').value).to eq(@data_visibility_member_id) if member_present
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

Then(/^I should see the advance availability (by term|by member) submit button (enabled|disabled$)/) do |form, state|
  form_selector = case form
  when 'by term'
    '.rules-availability-by-term-form'
  when 'by member'
    '.rules-availability-by-member-form'
  end
  if state == 'enabled'
    page.assert_no_selector("#{form_selector} input[type=submit][disabled]")
    page.assert_selector("#{form_selector} input[type=submit]", count: 2)
  else
    page.assert_selector("#{form_selector} input[type=submit][disabled]", count: 2)
  end
end

When(/^I click on the first checkbox in the vrc section of the advance availability by term form$/) do
  page.all('.rules-availability-by-term-vrc input[type=checkbox]').first.click
end

When(/^I click on the button to change the add advance availability status$/) do
  page.find('.advance-availability-status section:first-of-type a').click
end

When(/^I click on the checkbox to toggle the advance availability state of the first member$/) do
  page.all('.rules-availability-by-member-form input[type=checkbox]').first.click
end

When(/^I am on the advance availability by member admin page$/) do
  visit('/admin/rules/advance-availability/member')
end

When(/^I submit the form for advance availability by member$/) do
  page.all('.rules-availability-by-member-form input[type=submit]').first.click
end

When(/^I submit the form for advance availability by member and there is an error$/) do
  allow_any_instance_of(MembersService).to receive(:update_quick_advance_flags_for_members).and_return(nil)
  step 'I submit the form for advance availability by member'
end

Then(/^I should see the table of (scheduled early|typical) shutoffs$/) do |shutoff_type|
  parent_selector = if shutoff_type == 'scheduled early'
    '.advance-shutoff-times-early'
  else
    '.advance-shutoff-times-typical'
  end
  page.assert_selector("#{parent_selector} table")
end

When(/^I visit the admin early shutoff summary page$/) do
  visit('/admin/rules/advance-shutoff-times/early')
end

When(/^I click the button to schedule a new early shutoff$/) do
  page.find('.advance-shutoff-times-early a', text: /\A#{I18n.t('admin.shutoff_times.actions.schedule_new')}\z/i).click
end

Then(/^I should see the form to schedule a new early shutoff$/) do
  page.assert_selector('.rules-early-shutoff-form')
end

When(/^I input "(.*?)" in the field for the early shutoff day of message$/) do |text|
  page.find('.rules-early-shutoff-form section:first-of-type .input-field-container-textarea-wrapper textarea').set(text)
end

When(/^I click the button to confirm the scheduling of the (?:new|edited) early shutoff( but there is an error)?$/) do |error|
  if error
    allow_any_instance_of(RestClient::Resource).to receive(:post).and_raise(RestClient::Exception)
    allow_any_instance_of(RestClient::Resource).to receive(:put).and_raise(RestClient::Exception)
  end
  page.find('.rules-early-shutoff-form input[type=submit]').click
end

When(/^I click on the button to edit the typical shutoff times( but there is an error)?$/) do |error|
  allow_any_instance_of(RestClient::Resource).to receive(:put).and_raise(RestClient::Exception) if error
  page.find('.rules-typical-shutoff-form input[type=submit]').click
end

When(/^I click to edit the first scheduled early shutoff$/) do
  first_row = page.find('.advance-shutoff-times-early table tbody tr:first-child')
  @early_shutoff_id
  @early_shutoff_date = Date.strptime(first_row.find('td:first-child').text, '%m/%d/%Y')
  first_row.find('td:last-child a', text: /\A#{I18n.t('global.edit')}\z/i).click
end

When(/^I click to remove the first scheduled early shutoff( but there is an error)?$/) do |error|
  allow_any_instance_of(RestClient::Resource).to receive(:delete).and_raise(RestClient::Exception) if error
  page.find('.advance-shutoff-times-early table tbody tr:first-child td:last-child a', text: /\A#{I18n.t('global.remove')}\z/i).click
end

Then(/^I should be on the edit page for that early shutoff$/) do
  expect(page.find(".rules-early-shutoff-form input[name='early_shutoff_request[early_shutoff_date]']", visible: :hidden).value).to eq(@early_shutoff_date.iso8601)
end

When(/^I change the member selector to the (\d) value on the data visibility web flags page$/) do |selection|
  member_selection_node = page.find('.data-visibility-select-member select')
  member_selection_node.click
  member_option_node = member_selection_node.all('option')[selection.to_i]
  @data_visibility_member_id = member_option_node.value
  member_option_node.click
end

Then(/^I should see the data visibility web flags page for that member$/) do
  step 'I should see 6 report tables with multiple data rows'
  expect(page.find('.data-visibility-select-member select').value).to eq(@data_visibility_member_id)
end

When(/^I click to toggle the state of the first data source$/) do
  page.all('.data-visibility-flags-form input[type=checkbox]').first.click
end

Then(/^I should see the first data source in its disabled state$/) do
  first_row_classes = page.all('.data-visibility-flags-form table').first.find('tr:first-child')[:class]
  expect(first_row_classes).to include('data-source-disabled')
end

When(/^I click to save the data visibility changes( but there is an error)?$/) do |error|
  if error
    allow_any_instance_of(RestClient::Resource).to receive(:put).and_raise(RestClient::Exception)
  else
    allow_any_instance_of(RestClient::Resource).to receive(:put).and_call_original
  end
  page.all('.data-visibility-flags-form input[type=submit]').first.click
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
  when 'early shutoffs'
    I18n.t('admin.shutoff_times.nav.early')
  when 'typical shutoffs'
    I18n.t('admin.shutoff_times.nav.typical')
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

def css_selector_from_rules_section(rules_section)
  case rules_section
    when 'term rules'
      '.term-rules'
    when 'add advance availability'
      '.advance-availability'
    when 'end of day shutoff'
      '.advance-shutoff-times'
  end
end