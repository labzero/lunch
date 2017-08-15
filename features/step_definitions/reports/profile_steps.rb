When(/^I view the member profile from the bank selector$/) do
  @parent_window = page.driver.current_window_handle
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
  begin
    page.driver.within_window('/reports/profile') do
      step %{I see the profile report}
    end
  ensure
    page.driver.window_handles.each do |handle|
      page.driver.close_window(handle) unless handle == @parent_window
    end
    page.driver.switch_to_window(@parent_window)
  end
end