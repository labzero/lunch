Given(/^I am showing Settlement Transaction Account activities for the last (\d+) months$/) do |month|
  end_date = Time.zone.today
  month = month.to_i
  start_date = month.months.ago
  step 'I click the datepicker field'
  step %{I select a start date of "#{start_date}" and an end date of "#{end_date}"}
  step 'I click the datepicker apply button'
  step %{I should see a "Settlement Transaction Account Statement" with dates between "#{start_date.strftime('%B %-d, %Y')}" and "#{end_date.strftime('%B %-d, %Y')}"}
end

Then(/^I should only see "(.*?)" rows in the Settlement Transaction Account Statement table$/) do |text|
  column_heading = case text
  when 'Debit'
    I18n.t('global.debits')
  when 'Credit'
    I18n.t('global.credits')
  else
    text
  end
  page.assert_selector('.report-table thead th', text: column_heading)
  column_index = jquery_evaluate("$('.report-table thead th:contains(#{column_heading})').index()") + 1
  if !page.find(".report-table tbody tr:first-child td:first-child")['class'].split(' ').include?('dataTables_empty')
    page.all(".report-table tbody tr:not(.beginning-balance-row) td:nth-child(#{column_index})").each_with_index do |element, index|
      next if index == 0 # this is a hack to get around Capybara's inability to handle tr:not(.beginning-balance-row, .ending-balance-row). Apparently, Capybara can only handle one `not` selector
      expect(element.text.gsub(/\D/,'').to_f).to be > 0
      expect(element.text).to_not match(/\A\(.*\)\z/)
    end
  end
end