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

When(/^I click on the advances link in the header$/) do
  page.find('.secondary-nav li', text: I18n.t('global.advances')).click
end

