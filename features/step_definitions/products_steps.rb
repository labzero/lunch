Then(/^I should see the products summary page$/) do
  page.assert_selector('.products-summary-page')
end

Then(/^I should see the products summary page focused on the (advances|mpf_program) topic$/) do |topic|
  page.assert_selector('.products-summary-page')
  expect(current_url.ends_with?("##{topic}")).to eq(true)
end