Then(/^I should see the forms page$/) do
  page.assert_selector('.resource-forms-page')
end

Given(/^I am on the forms page$/) do
  visit '/resources/forms'
end

Then(/^I should see the forms page focused on the (agreements|authorizations|credit|collateral) topic$/) do |topic|
  page.assert_selector('.resource-forms-page')
  expect(current_url.ends_with?("##{topic}")).to eq(true)
end

Then(/^I should see at least one form to download$/) do
  page.assert_selector('.resource-form-table a', text: /\A#{Regexp.quote(I18n.t('global.view_pdf'))}\z/i, minimum: 1)
end

When(/^I click on the (agreements|authorizations|credit|collateral) link in the ToC$/) do |topic|
  click_link(I18n.t("resources.forms.#{topic}.title"))
end

Then(/^I should see the sign link for the "(.*?)" form$/) do |form|
  page.find('td', text: docusign_link(form) , exact: true).find(:xpath, "..").assert_selector('td a', text: /\A#{Regexp.quote(I18n.t('global.sign'))}\z/i)
end

When(/^I click on the sign link for the "(.*?)" form$/) do |form|
  page.find('td', text: docusign_link(form) , exact: true).find(:xpath, "..").find('td a', text: /\A#{Regexp.quote(I18n.t('global.sign'))}\z/i).click
end

Then(/^I should see the docusign flyout$/) do
  page.assert_selector('.flyout-confirmation-dialogue', visible: true)
end

Then(/^I should not see the docusign flyout$/) do
  page.assert_no_selector('.flyout-confirmation-dialogue')
  page.assert_selector('.flyout', visible: :hidden)
end

When(/^I cancel the docusign flyout$/) do
  page.find('.secondary-button', text: /#{I18n.t('global.cancel')}/i).click
end

When(/^I click on the Sign with Docusign button$/) do
  @current_window = page.driver.current_window_handle
  @docusign_window = window_opened_by do
    page.find('.primary-button', text: /#{I18n.t('resources.forms.docusign.sign')}/i).click
  end
end

Then(/^I should see Docusign website and close it$/) do
  page.driver.within_window((@docusign_window || current_window).handle) do
    expect(current_host).to match(/\A(https?:\/\/)?demo\.docusign\.net\z/)
  end
  page.driver.window_handles.each do |handle|
    page.driver.close_window(handle) unless handle == @current_window
  end
end

Then(/^I should see the "(.*?)" form error$/) do |error_type|
  text = case error_type
  when 'expiration date invalid'
    I18n.t('activemodel.errors.models.letter_of_credit_request.attributes.expiration_date.invalid')
  when 'expiration date before issue date'
    I18n.t('activemodel.errors.models.letter_of_credit_request.attributes.expiration_date.before_issue_date')
  when 'internal user not authorized'
    I18n.t('letters_of_credit.errors.not_authorized')
  when /^exceeds borrowing capacity by (\d+)$/
    I18n.t('letters_of_credit.errors.exceeds_borrowing_capacity', borrowing_capacity: fhlb_formatted_currency_whole($1, html: false))
  end
  page.assert_selector('.form-error-section p', text: text, exact: true)
end

def docusign_link(form)
  if form == 'access manager'
    I18n.t('resources.forms.authorizations.website.access_manager')
  elsif form == 'secureid token'
    I18n.t('resources.forms.authorizations.website.securid')
  end
end