Then(/^I should see the mcu file upload area$/) do
  page.assert_selector('.mcu-upload-area', visible: :visible)
end

When(/^I am on the new mortgage collateral update page$/) do
  visit '/mortgage-collateral-update/new'
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