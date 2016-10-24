Given(/^I enter my SecurID pin$/) do
  page.find('input[name=securid_pin]').set(Random.rand(9999).to_s.rjust(4, '0'))
end

Given(/^I enter my SecurID token$/) do
  page.find('input[name=securid_token]').set(Random.rand(999999).to_s.rjust(6, '0'))
end

When(/^I enter "([^"]*)" for my SecurID (pin|token)$/) do |value, field|
  page.find("input[name=securid_#{field}]").set(value)
end

Then(/^I shouldn't see the SecurID fields$/) do
  page.assert_no_selector("input[name=securid_pin]")
  page.assert_no_selector("input[name=securid_token]")
end

Given(/^I enter my SecurID pin and token$/) do
  step %{I enter my SecurID pin}
  step %{I enter my SecurID token}
end

Then(/^I should see SecurID errors$/) do
  page.assert_selector('.securid-form .form-error', visible: true)
  page.assert_selector('.securid-form input.input-field-error', visible: true)
end