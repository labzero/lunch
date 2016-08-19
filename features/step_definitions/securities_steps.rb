When(/^I click on the Securities link in the header$/) do
  page.find('.secondary-nav a', text: I18n.t('securities.title'), exact: true).click
end

Then(/^I should be on the (Manage Securities|Securities Requests|Securities Release|Safekeep Securities|Pledge Securities) page$/i) do |page_type|
  text = case page_type
    when /\AManage Securities\z/i
      step 'I should see a report table with multiple data rows'
      I18n.t('securities.manage.title')
    when /\ASecurities Requests\z/i
      step 'I should see a report table with multiple data rows'
      I18n.t('securities.requests.title')
    when /\ASecurities Release\z/i
      step 'I should see a report table with multiple data rows'
      I18n.t('securities.release.title')
    when /\ASafekeep Securities\z/i
      I18n.t('securities.safekeep.title')
    when /\APledge Securities\z/i
      I18n.t('securities.pledge.title')
  end
  page.assert_selector('h1', text: text, exact: true)
end

Then(/^I should see two securities requests tables with data rows$/) do
  page.assert_selector('.securities-request-table', count: 2)
  page.all('.securities-request-table').each do |table|
    table.assert_selector('tbody tr')
  end
end

When(/^I am on the (manage|release|release success|safekeep success|pledge success|safekeep|pledge) securities page$/) do |page|
  case page
  when 'manage'
    visit '/securities/manage'
  when 'release success'
    visit '/securities/release/success'
  when 'pledge success'
    visit '/securities/pledge/success'
  when 'safekeep success'
    visit '/securities/safekeep/success'
  when 'release'
    step 'I am on the manage securities page'
    step 'I check the 1st Pledged security'
    step 'I click the button to release the securities'
  when 'safekeep'
    visit '/securities/safekeep/edit'
  when 'pledge'
    visit '/securities/pledge/edit'
  end
end

Given(/^I am on the securities request page$/) do
  visit '/securities/requests'
end

When(/^I filter the securities by (Safekept|Pledged|All)$/) do |filter|
  page.find('.securities-status-filter span', text: filter, exact: true).click
end

Then(/^I should only see (Safekept|Pledged|All) rows in the securities table$/) do |filter|
  column_index = jquery_evaluate("$('.report-table thead th:contains(#{I18n.t('common_table_headings.status')})').index()") + 1
  if table_not_empty
    page.all(".manage-securities-table td:nth-child(#{column_index})").each_with_index do |element, index|
      expect(element.text).to eq(filter)
    end
  end
end

When(/^I (check|uncheck) the (\d+)(?:st|nd|rd|th) (Pledged|Safekept) security$/) do |checked, i, status|
  if table_not_empty
    index = i.to_i - 1
    checkbox = page.all(".manage-securities-form input[type=checkbox][data-status='#{status}']")[index]
    checkbox.click
    expect(checkbox.checked?).to eq(checked == 'check')
  end
end

When(/^I remember the cusip value of the (\d+)(?:st|nd|rd|th) (Pledged|Safekept) security$/) do |i, status|
  checkbox_name = :"@#{status.downcase}#{i}"
  index = i.to_i - 1
  cusip = page.all(".manage-securities-form input[type=checkbox][data-status='#{status}']")[index].first(:xpath,".//..//..").find('td:nth-child(2)').text
  instance_variable_set(checkbox_name, cusip)
end

Then(/^I should see the cusip value from the (\d+)(?:st|nd|rd|th) (Pledged|Safekept) security in the (\d+)(?:st|nd|rd|th) row of the securities table$/) do |i, status, row|
  remembered_cusip = instance_variable_get(:"@#{status.downcase}#{i}")
  cusip = page.find(".securities-release-table tbody tr:nth-child(#{row}) td:first-child").text
  expect(remembered_cusip).to eq(cusip)
end

Then(/^the release securities button should be (active|inactive)$/) do |active|
  if table_not_empty
    if active == 'active'
      page.assert_selector('.manage-securities-form input[type=submit]')
      page.assert_no_selector('.manage-securities-form input[type=submit]:disabled')
    else
      page.assert_selector('.manage-securities-form input[type=submit]:disabled')
    end
  end
end

When(/^I click the button to release the securities$/) do
  page.find('.manage-securities-form input[type=submit]').click
end

When(/^I click the button to create a new (safekeep|pledge) request$/) do |type|
  page.find(".manage-securities-table-actions a.#{type}").click
end

Then(/^I should see "(.*?)" as the selected release delivery instructions$/) do |instructions|
  text = delivery_instructions(instructions)
  page.assert_selector('.securities-delivery-instructions .dropdown-selection', text: text, exact: true)
end

Then(/^I should see the "(.*?)" release instructions fields$/) do |instructions|
  selector = case instructions
    when 'DTC'
      'dtc'
    when 'Fed'
      'fed'
    when 'Mutual Fund'
      'mutual-fund'
    when 'Physical'
      'physical-securities'
  end
  page.assert_selector(".securities-delivery-instructions-field-#{selector}", visible: :visible)
end

When(/^I select "(.*?)" as the release delivery instructions$/) do |instructions|
  text = delivery_instructions(instructions)
  page.find('.securities-delivery-instructions .dropdown').click
  page.find('.securities-delivery-instructions .dropdown li', text: text, exact: true).click
end

When(/^I click the button to delete the release$/) do
  page.find('.delete-release-trigger').click
end

Then(/^I should see the delete release flyout dialogue$/) do
  page.assert_selector('.flyout-confirmation-dialogue', visible: 'visible')
end

Then(/^I should not see the delete release flyout dialogue$/) do
  page.assert_no_selector('.flyout-confirmation-dialogue', visible: 'visible')
end

When(/^I click on the button to continue with the release$/) do
  page.find('.delete-release-flyout button', text: I18n.t('securities.release.delete_request.continue').upcase).click
end

When(/^I click on the button to delete the release$/) do
  page.find('.delete-release-flyout a', text: I18n.t('securities.release.delete_request.delete').upcase).click
end

When(/^I click on the Edit Securities link$/) do
  page.find('.securities-download').click
end

When(/^I click on the Learn How link$/) do
  page.find('.securities-download-safekeep-pledge').click
end

Then(/^I should see instructions on how to (edit|upload) securities$/) do |action|
  page.assert_selector(".securities-#{action == 'edit' ? 'download' : 'upload'}-instructions", visible: :visible)
end

Then(/^I should not see instructions on how to (edit|upload) securities$/) do |action|
  page.assert_selector(".securities-#{action == 'edit' ? 'download' : 'upload'}-instructions", visible: :hidden)
end

When(/^the edit securities section is open$/) do
  step 'I click on the Edit Securities link'
  step 'I should see instructions on how to edit securities'
end

When(/^I drag and drop the "(.*?)" file into the edit securities dropzone$/) do |filename|
  # Simulate drag and drop of given file
  page.execute_script("seleniumUpload = window.$('<input/>').attr({id: 'seleniumUpload', type:'file'}).appendTo('body');")
  attach_file('seleniumUpload', Rails.root + "spec/fixtures/#{filename}")
  page.execute_script("e = $.Event('drop'); e.originalEvent = {dataTransfer : { files : seleniumUpload.get(0).files } }; $('.securities-download-instructions').trigger(e);")
end

Then(/^I should see an upload progress bar$/) do
  page.assert_selector('.file-upload-progress .gauge-section', visible: :visible)
end

When(/^I click to cancel the securities release file upload$/) do
  page.find('.file-upload-progress p', text: I18n.t('global.cancel_upload').upcase, exact: true).click
end

Then(/^I should not see an upload progress bar$/) do
  page.assert_selector('.file-upload-progress .gauge-section', visible: :hidden)
end

When(/^I click the (trade|settlement) date datepicker$/) do |field|
  text = case field
  when 'trade'
    I18n.t('common_table_headings.trade_date')
  when 'settlement'
    I18n.t('common_table_headings.settlement_date')
  else
    raise ArgumentError.new("Unknown datepicker field: #{field}")
  end
  field_container = page.find('.securities-broker-instructions .input-field-container-horizontal', text: text, exact: true, visible: :visible)
  field_container.find('.datepicker-trigger').click
end

Then(/^I should see a list of securities authorized users$/) do
  page.assert_selector('h2', text: /\A#{Regexp.quote(I18n.t('securities.success.authorizers'))}\z/, visible: true)
  page.assert_selector('.settings-users-table', visible: true)
end

Then(/^I should see the title for the "(.*?)" page$/) do |success_page|
  translation = case success_page
    when 'release success'
      'securities.success.title'
    when 'pledge success'
      'securities.safekeep_pledge.success.pledge'
    when 'safekeep success'
      'securities.safekeep_pledge.success.safekeep'
  end
  page.assert_selector('.securities-header h1', text: I18n.t(translation), exact: true)
end

When(/^I fill in the "(.*?)" securities field with "(.*?)"$/) do |field_name, value|
  page.fill_in("securities_release_request[#{field_name}]", with: value)
end

When(/^I submit the securities release request for authorization$/) do
  page.find('.securities-submit-release-form input[type=submit]').click
end

Then(/^I should see the success page for the securities release request$/) do
  page.assert_selector('.securities h1', text: I18n.t('securities.success.title'))
end

Then(/^I should see the generic error message for the securities release request$/) do
  page.assert_selector('.securities-submit-release-form-errors p', text: I18n.t('securities.release.edit.generic_error', phone_number: securities_services_phone_number, email: securities_services_email_text), exact: true)
end

Then(/^Account Number should be disabled$/) do
  page.assert_selector('#securities_release_request_account_number[disabled]')
end

Then(/^I should a disabled state for the Authorize action$/) do
  page.assert_selector('.securities-request-table .report-cell-actions', text: I18n.t('securities.requests.actions.authorize').upcase, exact: true)
  page.assert_no_selector('.securities-request-table .report-cell-actions a', text: I18n.t('securities.requests.actions.authorize').upcase, exact: true)
end

Then(/^I should an active state for the Authorize action$/) do
  page.assert_selector('.securities-request-table .report-cell-actions a', text: I18n.t('securities.requests.actions.authorize').upcase, exact: true)
end

When(/^I click to Authorize the first (pledge|release|safekeep)(?: request)?$/) do |type|
  description = case type
  when 'pledge'
    I18n.t('securities.requests.form_descriptions.pledge')
  when 'release'
    I18n.t('securities.requests.form_descriptions.release')
  when 'safekeep'
    I18n.t('securities.requests.form_descriptions.safekept')
  else
    raise ArgumentError, "unknown form type: #{type}"
  end
  row = page.all('.securities-request-table td', text: description, exact: true).first.find(:xpath, '..')
  row.find('.report-cell-actions a', text: I18n.t('securities.requests.actions.authorize').upcase, exact: true).click
end

Then(/^I should see "(.*?)" as the selected pledge type$/) do |type|
  page.assert_selector('.securities-broker-instructions .pledge_type .dropdown-selection', text: pledge_types(type), exact: true)
end

When(/^I authorize the request$/) do
  step %{I enter my SecurID pin and token}
  step %{I click to authorize the request}
end

When(/^I click to authorize the request$/) do
  page.find(".securities-actions .primary-button[value=#{I18n.t('securities.release.authorize')}]").click
end

Then(/^I should see the authorize request success page$/) do
  page.assert_selector('.securities-authorize-success')
end

Then(/^the Authorize action is (disabled|enabled)$/) do |state|
  base = ".securities-actions .primary-button[value=#{I18n.t('securities.release.authorize')}]"
  if state == 'disabled'
    page.assert_selector(base + '[disabled]')
  else
    page.assert_selector(base + ':not([disabled])')
  end
end

When(/^I choose the first available date for (trade|settlement) date$/) do |attr|
step "I click the #{attr} date datepicker"
step 'I choose the first available date'
end

def delivery_instructions(text)
  case text
  when 'DTC'
    I18n.t('securities.release.delivery_instructions.dtc')
  when 'Fed'
    I18n.t('securities.release.delivery_instructions.fed')
  when 'Mutual Fund'
    I18n.t('securities.release.delivery_instructions.mutual_fund')
  when 'Physical'
    I18n.t('securities.release.delivery_instructions.physical_securities')
  end
end

def pledge_types(text)
  case text
  when 'SBC'
    I18n.t('securities.release.pledge_type.sbc')
  when 'Standard'
    I18n.t('securities.release.pledge_type.standard')
  end
end

def table_not_empty
  !page.find(".report-table tbody tr:first-child td:first-child")['class'].split(' ').include?('dataTables_empty')
end