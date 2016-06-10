When(/^I click on the Securities link in the header$/) do
  page.find('.secondary-nav a', text: I18n.t('securities.title'), exact: true).click
end

Then(/^I should be on the (Manage Securities|Securities Requests) page$/) do |page_type|
  text = case page_type
    when 'Manage Securities'
      I18n.t('securities.manage.title')
    when 'Securities Requests'
      I18n.t('securities.requests.title')
  end
  page.assert_selector('h1', text: text, exact: true)
  step 'I should see a report table with multiple data rows'
end

Then(/^I should see two securities requests tables with data rows$/) do
  page.assert_selector('.securities-request-table', count: 2)
  page.all('.securities-request-table').each do |table|
    table.assert_selector('tbody tr')
  end
end

When(/^I am on the (manage|release) securities page$/) do |page|
  case page
  when 'manage'
    visit '/securities/manage'
  when 'release'
    step 'I am on the manage securities page'
    step 'I check the 1st Pledged security'
    step 'I click the button to release the securities'
  end
end

When(/^I filter the securities by (Safekept|Pledged|All)$/) do |filter|
  page.find('.securities-status-filter span', text: filter, exact: true).click
end

Then(/^I should only see (Safekept|Pledged|All) rows in the securities table$/) do |filter|
  column_index = jquery_evaluate("$('.report-table thead th:contains(#{I18n.t('common_table_headings.status')})').index()") + 1
  if table_not_empty
    page.all(".manage-securities-table td:nth-child(#{column_index})").each_with_index do |element, index|
      expect(element.text).to eq(filter)
    end
  end
end

When(/^I (check|uncheck) the (\d+)(?:st|nd|rd|th) (Pledged|Safekept) security$/) do |checked, i, status|
  if table_not_empty
    index = i.to_i - 1
    checkbox = page.all(".manage-securities-form input[type=checkbox][data-status='#{status}']")[index]
    checkbox.click
    expect(checkbox.checked?).to eq(checked == 'check')
  end
end

When(/^I remember the cusip value of the (\d+)(?:st|nd|rd|th) (Pledged|Safekept) security$/) do |i, status|
  checkbox_name = :"@#{status.downcase}#{i}"
  index = i.to_i - 1
  cusip = page.all(".manage-securities-form input[type=checkbox][data-status='#{status}']")[index].first(:xpath,".//..//..").find('td:nth-child(2)').text
  instance_variable_set(checkbox_name, cusip)
end

Then(/^I should see the cusip value from the (\d+)(?:st|nd|rd|th) (Pledged|Safekept) security in the (\d+)(?:st|nd|rd|th) row of the securities table$/) do |i, status, row|
  remembered_cusip = instance_variable_get(:"@#{status.downcase}#{i}")
  cusip = page.find(".securities-release-table tbody tr:nth-child(#{row}) td:first-child").text
  expect(remembered_cusip).to eq(cusip)
end

Then(/^the release securities button should be (active|inactive)$/) do |active|
  if table_not_empty
    if active == 'active'
      page.assert_selector('.manage-securities-form input[type=submit]')
      page.assert_no_selector('.manage-securities-form input[type=submit]:disabled')
    else
      page.assert_selector('.manage-securities-form input[type=submit]:disabled')
    end
  end
end

When(/^I click the button to release the securities$/) do
  page.find('.manage-securities-form input[type=submit]').click
end

Then(/^I should see "(.*?)" as the selected release delivery instructions$/) do |instructions|
  text = delivery_instructions(instructions)
  page.assert_selector('.securities-delivery-instructions .dropdown-selection', text: text, exact: true)
end

Then(/^I should see the "(.*?)" release instructions fields$/) do |instructions|
  selector = case instructions
    when 'DTC'
      'dtc'
    when 'Fed'
      'fed'
    when 'Mutual Fund'
      'mutual-fund'
    when 'Physical'
      'physical'
  end
  page.assert_selector(".securities-delivery-instructions-field-#{selector}", visible: :visible)
end

When(/^I select "(.*?)" as the release delivery instructions$/) do |instructions|
  text = delivery_instructions(instructions)
  page.find('.securities-delivery-instructions .dropdown').click
  page.find('.securities-delivery-instructions .dropdown li', text: text, exact: true).click
end

When(/^I click the button to delete the release$/) do
  page.find('.delete-release-trigger').click
end

Then(/^I should see the delete release flyout dialogue$/) do
  page.assert_selector('.flyout-confirmation-dialogue', visible: 'visible')
end

Then(/^I should not see the delete release flyout dialogue$/) do
  page.assert_no_selector('.flyout-confirmation-dialogue', visible: 'visible')
end

When(/^I click on the button to continue with the release$/) do
  page.find('.delete-release-flyout button', text: I18n.t('securities.release.delete_request.continue').upcase).click
end

When(/^I click on the button to delete the release$/) do
  page.find('.delete-release-flyout a', text: I18n.t('securities.release.delete_request.delete').upcase).click
end

When(/^I click on the Edit Securities link$/) do
  page.find('.securities-download').click
end

Then(/^I should see instructions on how to edit securities$/) do
  page.assert_selector('.securities-download-instructions', visible: :visible)
end

Then(/^I should not see instructions on how to edit securities$/) do
  page.assert_selector('.securities-download-instructions', visible: :hidden)
end

def delivery_instructions(text)
  case text
    when 'DTC'
      I18n.t('securities.release.delivery_instructions.dtc')
    when 'Fed'
      I18n.t('securities.release.delivery_instructions.fed')
    when 'Mutual Fund'
      I18n.t('securities.release.delivery_instructions.mutual_fund')
    when 'Physical'
      I18n.t('securities.release.delivery_instructions.physical_securities')
  end
end

def table_not_empty
  !page.find(".report-table tbody tr:first-child td:first-child")['class'].split(' ').include?('dataTables_empty')
end

