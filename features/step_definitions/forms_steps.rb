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

Then(/^I should see "([^"]*)" link$/) do |arg1|
  page.assert_selector('.resource-form-table a', text: /\A#{Regexp.quote(I18n.t('global.sign'))}\z/i, minimum: 1)
end

When(/^I click on the sign link$/) do
  click_link(I18n.t('global.sign'))
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
