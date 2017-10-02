Then(/^I should see the mcu file upload area$/) do
  page.assert_selector('.mcu-upload-area', visible: :visible)
end

When(/^I am on the new mortgage collateral update page$/) do
  visit '/mortgage-collateral-update/new'
end

When(/^I am on the manage mortgage collateral updates page$/) do
  visit '/mortgage-collateral-update/manage'
end

Then(/^I should see the (enabled|disabled) state of the (pledge|mcu|program) type dropdown$/) do |state, dropdown|
  dropdown_node = find_dropdown_node(dropdown)
  if state == 'disabled'
    expect(dropdown_node['disabled']).to eq('true')
  else
    expect(dropdown_node['disabled']).to be nil
  end
end

When(/^I click on the (pledge|mcu|program) type dropdown$/) do |dropdown|
  dropdown_node = find_dropdown_node(dropdown)
  dropdown_node.click
end

When(/^I select "(.*?)" from the (pledge|mcu|program) type dropdown$/) do |option, dropdown|
  dropdown_node = find_dropdown_node(dropdown)
  dropdown_node.find('li', text: option).click
end

Then(/^I (should|should not) see "(.*?)" as an option in the (pledge|mcu|program) type dropdown$/) do |permission, option, dropdown|
  dropdown_node = find_dropdown_node(dropdown)
  if permission == 'should'
    dropdown_node.assert_selector('li', text: option, visible: :visible)
  else
    dropdown_node.assert_selector('li', text: option, visible: :hidden)
  end
end

When(/^I (should|should not) see (any|specific identification|blanket lien) mcu legal copy$/) do |permission, copy_type|
  selector = case copy_type
  when 'any'
    '.mcu-upload-legal-section'
  when 'specific identification'
    '.mcu-upload-legal-section-specific'
  when 'blanket lien'
    '.mcu-upload-legal-section-blanket-lien'
  end
  if permission == 'should'
    page.assert_selector(selector)
  else
    page.assert_no_selector(selector)
  end
end

When(/^I click on the View Details link in the first row of the MCU Recent Requests table$/) do
  first_row_cells = page.all('.mortgages-manage-report-table tbody tr:first-child td')
  @transaction_number = first_row_cells[0].text
  @mcu_type = first_row_cells[1].text
  @status = first_row_cells[4].text
  page.find('.mortgages-manage-report-table tbody tr:first-child a', text: /#{I18n.t('mortgages.manage.actions.view_details')}/i).click
end

Then(/^I should see a list of transaction details for the transaction that was in the first row of the MCU Recent Request table$/) do
  transaction_number = page.all(:xpath, "//dt[text()='#{I18n.t('mortgages.manage.transaction_number')}']/following-sibling::dd").first.text
  mcu_type = page.all(:xpath, "//dt[text()='#{I18n.t('mortgages.new.transaction.mcu')}']/following-sibling::dd").first.text
  status = page.all(:xpath, "//dt[text()='#{I18n.t('mortgages.manage.status')}']/following-sibling::dd").first.text

  expect(transaction_number).to eq(@transaction_number)
  expect(mcu_type).to eq(@mcu_type)
  expect(status).to eq(@status)
end

When(/^I click on the Manage MCUS button$/) do
  page.find('.secondary-button', text: /#{I18n.t('mortgages.view.actions.manage')}/i).click
end

def find_dropdown_node(name)
  case name
  when 'pledge'
    page.find('.mcu-pledge-type-dropdown')
  when 'mcu'
    page.find('.mcu-mcu-type-dropdown')
  when 'program'
    page.find('.mcu-program-type-dropdown')
  end
end