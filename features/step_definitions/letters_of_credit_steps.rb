Then(/^I (should|should not) see the letters of credit dropdown for Request Letter of Credit$/) do |permission|
  step 'I click on the letters of credit link in the header'
  if permission == 'should'
    page.assert_selector('.page-header .secondary-nav a', text: I18n.t('letters_of_credit.request.title'), exact: true)
  else
    page.assert_no_selector('.page-header .secondary-nav a', text: I18n.t('letters_of_credit.request.title'), exact: true)
  end
end

When(/^I visit the (Manage Letters of Credit|Request Letter of Credit) page$/) do |page|
  case page
  when 'Manage Letters of Credit'
    visit '/letters-of-credit/manage'
  when 'Request Letter of Credit'
    visit '/letters-of-credit/request'
  end
end

Then(/^I (should|should not) see the button to request a new letter of credit$/) do |permission|
  if permission == 'should'
    page.assert_selector('.secondary-button', text: /\A#{I18n.t('letters_of_credit.manage.request')}\z/i)
  else
    page.assert_no_selector('.secondary-button', text: /\A#{I18n.t('letters_of_credit.manage.request')}\z/i)
  end
end