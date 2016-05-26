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

When(/^I am on the (manage) securities page$/) do |page|
  case page
  when 'manage'
    visit '/securities/manage'
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

def table_not_empty
  !page.find(".report-table tbody tr:first-child td:first-child")['class'].split(' ').include?('dataTables_empty')
end

