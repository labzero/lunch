include CustomFormattingHelper

Then(/^I (should|should not) see the letters of credit dropdown for Request Letter of Credit$/) do |permission|
  step 'I click on the letters of credit link in the header'
  if permission == 'should'
    page.assert_selector('.page-header .secondary-nav a', text: I18n.t('letters_of_credit.request.title'), exact: true)
  else
    page.assert_no_selector('.page-header .secondary-nav a', text: I18n.t('letters_of_credit.request.title'), exact: true)
  end
end

When(/^I visit the (Manage Letters of Credit|Request Letter of Credit|Preview Letter of Credit|Letter of Credit Success|Request Letter of Credit Amendment|Preview Letter of Credit Amendment) page$/) do |page|
  case page
  when 'Manage Letters of Credit'
    visit '/letters-of-credit/manage'
  when 'Request Letter of Credit'
    visit '/letters-of-credit/request'
  when 'Preview Letter of Credit'
    visit '/letters-of-credit/request'
    step 'I enter 1234 in the letter of credit amount field'
    step 'I click the Preview Request button'
    step 'I should be on the Preview Letter of Credit Request page'
  when 'Letter of Credit Success'
    step 'I visit the Preview Letter of Credit page'
    step 'I enter my SecurID pin'
    step 'I enter my SecurID token'
    step 'I click the Authorize Request button'
  when 'Request Letter of Credit Amendment'
    visit '/letters-of-credit/amend?lc_number=2014-011'
  when 'Preview Letter of Credit Amendment'
    visit '/letters-of-credit/amend?lc_number=2014-011'
    step 'I enter 14750001 in the letter of credit amended_amount field'
    step 'I click the Preview Request button'
    step 'I should be on the Preview Letter of Credit Amendment page'
  end
end

Then(/^I (should|should not) see the button to request a new letter of credit$/) do |permission|
  if permission == 'should'
    page.assert_selector('.secondary-button', text: /\A#{I18n.t('letters_of_credit.manage.request')}\z/i)
  else
    page.assert_no_selector('.secondary-button', text: /\A#{I18n.t('letters_of_credit.manage.request')}\z/i)
  end
end

Then(/^I (should|should not) see the link to amend an existing letter of credit$/) do |permission|
  if permission == 'should'
    page.assert_selector('.amend_loc_link', text: /\A#{I18n.t('global.amend')}\z/i)
  else
    page.assert_no_selector('.amend_loc_link', text: /\A#{I18n.t('global.amend')}\z/i)
  end
end

Then(/^I should see the Preview Request button in its (enabled|disabled) state$/) do |state|
  base = "input[type=submit][value='#{I18n.t('letters_of_credit.preview.action')}']"
  if state == 'enabled'
    page.assert_selector(base + ':not([disabled])')
  else
    page.assert_selector(base + '[disabled]')
  end
end

When(/^I enter (\d+) in the letter of credit (amount|amended_amount) field$/) do |amount, field|
  page.find("input[name='letter_of_credit_request[#{field}]'").set(amount)
end

When(/^I try to enter "(.*?)" in the letter of credit (amount|amended_amount) field$/) do |amount, field|
  page.find("input[name='letter_of_credit_request[#{field}]'").set(amount)
end

Then(/^I should see that the amount in the (preview new request|preview amendment request) is (\d+)/) do |page_type, amount|
  text = case page_type
  when /\Apreview new request\z/i
    I18n.t('letters_of_credit.request.amount')
  when /\Apreview amendment request\z/i
    I18n.t('letters_of_credit.request.amend.requested.amended_amount')
  end
  amount_node = page.find('.form-summary-data dt', text: text)
  amount_node.find(:xpath,"..").assert_selector('dd .number-positive', text: fhlb_formatted_currency_whole(amount.to_i, {html: false}))
end

When(/^I choose the (first|last) possible date for the (issue|expiration|amended expiration) date$/) do |position, attr|
  step "I click the #{attr} date letter of credit datepicker"
  step "I choose the #{position} possible date"
end

When(/^I click the (issue|expiration|amended expiration) date letter of credit datepicker$/) do |field|
  case field
  when 'issue'
    text = I18n.t('letters_of_credit.preview.issue_date')
    page_type = 'letter-of-credit-preview'
  when 'expiration'
    text = I18n.t('letters_of_credit.manage.expiration_date')
    page_type = 'letter-of-credit-preview'
    when 'amended expiration'
    text = I18n.t('letters_of_credit.request.amend.requested.amended_expiration')
    page_type = 'letter-of-credit-amend-preview'
    else
    raise ArgumentError.new("Unknown datepicker field: #{field}")
  end
  field_container = page.find(".#{page_type} .input-field-container-horizontal", text: text, exact: true, visible: :visible)
  field_container.find('.datepicker-trigger').click
end

When(/^I click the (Preview Request|Authorize Request|Make a New Request|Manage Letters of Credit|Download Letter of Credit Request) button$/) do |button|
  text = case button
  when 'Preview Request'
    I18n.t('letters_of_credit.preview.action')
  when 'Authorize Request'
    I18n.t('letters_of_credit.preview.authorize')
  when 'Make a New Request'
    I18n.t('letters_of_credit.success.new_request')
  when 'Manage Letters of Credit'
    I18n.t('letters_of_credit.manage.title')
  when 'Download Letter of Credit Request'
    jquery_execute("$('body').on('downloadStarted', function(){$('body').addClass('download-started')})")
    I18n.t('letters_of_credit.success.download_pdf')
  end
  if ['Preview Request', 'Authorize Request'].include?(button)
    page.find("input[type=submit][value='#{text}']").click
  else
    page.find('.letters-of-credit a', text: /\A#{text}\z/i).click
  end
end

Then(/^I should see summary data for the letter of credit on the (letter of credit request|letter of credit preview|letter of credit amendment) page$/) do |page_type|
  type = case page_type
    when 'letter of credit request'
      '.letter-of-credit-request-form'
    when 'letter of credit preview'
      '.letter-of-credit-preview'
    when 'letter of credit amendment'
      '.letter-of-credit-amend-preview'
  end
  page.assert_selector("#{type} .form-summary-data", visible: true)
end

Then(/^the letter of credit (amount|amended_amount) field should be blank$/) do |field|
  expect(page.find("input[name='letter_of_credit_request[#{field}]']").value).to eq('')
end

Then(/^the letter of credit (amount|amended_amount) field should show "(.*?)"$/) do |field, text|
  expect(page.find("input[name='letter_of_credit_request[#{field}]'").value).to eq(text)
end

When(/^I set the Letter of Credit Request (issue|expiration|amended expiration) date to (\d+) (weeks|months) from today$/) do |field, n, unit|
  field = case field
    when 'issue'
      'issue_date'
    when 'expiration'
      'expiration_date'
    when 'amended expiration'
      'amended_expiration_date'
  end
  field_date = Time.zone.today + n.to_i.send(:"#{unit}")
  field_date = CalendarService.new(ActionDispatch::TestRequest.new).find_next_business_day(field_date, 1.day).to_s
  page.execute_script("$('input[name=\"letter_of_credit_request[#{field}]\"]').val(\"#{field_date}\")")
end

When(/^I set the Letter of Credit Request issue date to today$/) do
  page.execute_script("$('input[name=\"letter_of_credit_request[issue_date]\"]').val(\"#{Time.zone.today.to_s}\")")
end

Then(/^I should see that my bank is not authorized to request a Letter of Credit$/) do
  page.assert_text(ActionView::Base.full_sanitizer.sanitize(I18n.t('letters_of_credit.manage.not_authorized', url: '#').html_safe))
end

When(/^I click on Add Beneficiary link$/) do
  page.find('.beneficiaries-add').click
end

When(/^I click the amend link on a Letter of Credit row$/) do
  row = page.find('.letters-of-credit-manage-amend-on-table tbody tr:first-child')
  @lc_number = row.find('td:first-child').text
  row.find('td a', text: /\A#{I18n.t('global.amend').upcase}\z/, match: :first).click
end

Then(/^I should be on the Request Letter of Credit Amendment page$/) do
  page.assert_selector('.letters-of-credit-amend-request')
end

Then(/^I should be on the Preview Letter of Credit Amendment page$/) do
  page.assert_selector('.letter-of-credit-amend-preview')
end