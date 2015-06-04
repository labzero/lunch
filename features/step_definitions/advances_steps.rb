When(/^I select "(.*?)" from the advances dropdown$/) do |advances|
  step 'I don\'t see the advances dropdown'
  step 'I hover on the advances link in the header'
  page.find('.nav-dropdown').click_link(advances)
end

Then(/^I should see active advances data$/) do
  page.assert_selector('.advances-main-body', visible: true)
end

Then(/^I should see a advances table with multiple data rows$/) do
  page.assert_selector('.report-table tbody tr')
end

Given(/^I am on the "(.*?)" advances page$/) do |advances|
  sleep_if_close_to_midnight
  @today = Time.zone.now.to_date
  case advances
    when 'Manage Advances'
      visit '/advances/manage-advances'
    else
      raise Capybara::ExpectationNotMet, 'unknown report passed as argument'
  end
end

Given(/^I don't see the advances dropdown$/) do
  page.find('.logo').hover # make sure the mouse isn't left on top of the reports dropdown from a different test
  advances_menu = page.find('.nav-menu', text: I18n.t('global.advances'))
  advances_menu.parent.assert_selector('.nav-dropdown', visible: :hidden)
end

When(/^I hover on the advances link in the header$/) do
  page.find('.nav-menu', text: I18n.t('global.advances')).hover
end

