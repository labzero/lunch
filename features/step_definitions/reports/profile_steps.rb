When(/^I view the member profile from the bank selector$/) do
  page.find('.welcome form .welcome-profile').click
end

Then(/^I should see the member profile button (enabled|disabled)$/) do |state|
  selector = '.welcome form .welcome-profile'
  selector = selector + '[disabled]' if state == 'disabled'
  page.assert_selector(selector)
end

Then(/^I should not see the member profile button$/) do
  page.assert_no_selector('.welcome form .welcome-profile')
end

Then(/^I see the profile report$/) do
  page.assert_selector('.report.report-profile')
end

Then(/^I see the profile report in a new window and close it$/) do
  current_window = page.driver.current_window_handle
  begin
    page.driver.within_window('/reports/profile') do
      step %{I see the profile report}
    end
  ensure
    page.driver.window_handles.each do |handle|
      page.driver.close_window(handle) unless handle == current_window
    end
  end
end