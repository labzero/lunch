include CustomFormattingHelper

Then(/^I (should|should not) see the letters of credit dropdown for Request Letter of Credit$/) do |permission|
  step 'I click on the letters of credit link in the header'
  if permission == 'should'
    page.assert_selector('.page-header .secondary-nav a', text: I18n.t('letters_of_credit.request.title'), exact: true)
  else
    page.assert_no_selector('.page-header .secondary-nav a', text: I18n.t('letters_of_credit.request.title'), exact: true)
  end
end

When(/^I visit the (Manage Letters of Credit|Request Letter of Credit|Preview Letter of Credit) page$/) do |page|
  case page
  when 'Manage Letters of Credit'
    visit '/letters-of-credit/manage'
  when 'Request Letter of Credit'
    visit '/letters-of-credit/request'
  when 'Preview Letter of Credit'
    visit '/letters-of-credit/request'
    step 'I enter 1234567 in the letter of credit amount field'
    step 'I click the Preview Request button'
  end
end

Then(/^I (should|should not) see the button to request a new letter of credit$/) do |permission|
  if permission == 'should'
    page.assert_selector('.secondary-button', text: /\A#{I18n.t('letters_of_credit.manage.request')}\z/i)
  else
    page.assert_no_selector('.secondary-button', text: /\A#{I18n.t('letters_of_credit.manage.request')}\z/i)
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

When(/^I enter (\d+) in the letter of credit amount field$/) do |amount|
  page.find('input[name="letter_of_credit[amount]"]').set(amount)
end

Then(/^I should see that the amount in the preview is (\d+)/) do |amount|
  amount_node = page.find('.form-summary-data dt', text: I18n.t('letters_of_credit.request.amount'))
  amount_node.find(:xpath,"..").assert_selector('dd .number-positive', text: fhlb_formatted_currency_whole(amount.to_i, {html: false}))
end

When(/^I choose the (first|last) possible date for the (issue|expiration) date$/) do |position, attr|
  step "I click the #{attr} date letter of credit datepicker"
  step "I choose the #{position} possible date"
end

When(/^I click the (issue|expiration) date letter of credit datepicker$/) do |field|
  text = case field
  when 'issue'
    I18n.t('letters_of_credit.preview.issue_date')
  when 'expiration'
    I18n.t('letters_of_credit.manage.expiration_date')
  else
    raise ArgumentError.new("Unknown datepicker field: #{field}")
  end
  field_container = page.find('.letter-of-credit-preview .input-field-container-horizontal', text: text, exact: true, visible: :visible)
  field_container.find('.datepicker-trigger').click
end

When(/^I click the (Preview Request|Authorize Request) button$/) do |button|
  text = case button
  when 'Preview Request'
    I18n.t('letters_of_credit.preview.action')
  when 'Authorize Request'
    I18n.t('letters_of_credit.preview.authorize')
  end
  page.find("input[type=submit][value='#{text}']").click
end

Then(/^I should see summary data for the letter of credit$/) do
  page.assert_selector('.letter-of-credit-request-form .form-summary-data', visible: true)
end