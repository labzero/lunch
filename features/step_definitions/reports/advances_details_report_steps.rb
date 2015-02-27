Then(/^I should see advances details for today$/) do
  check_advances_details_for_date(Time.zone.now.to_date)
end

Then(/^I should see advances details for the (\d+)(?:st|rd|th) of (this|last) month$/) do |day, month|
  today = Time.zone.now.to_date
  if month == 'this'
    date = Date.new(today.year, today.month, day)
  else
    last_month = today - 1.month
    date = Date.new(last_month.year, last_month.month, day.to_i)
  end
  check_advances_details_for_date(date)
end

When(/^I click on the view cell for the first advance$/) do
  skip_if_table_empty do
    column_index = page.evaluate_script("$('.report-table thead th:contains(#{I18n.t('reports.pages.advances_detail.advance_number')})').index()") + 1
    @advance_number = page.find(".report-table tbody tr:first-child td:nth-child(#{column_index})").text
    page.find('.report-table tr:first-child .detail-view-trigger').click
  end
end

Then(/^I should see the detailed view for the first advance$/) do
  skip_if_table_empty do
    page.assert_selector('.report-table tr:first-child .advance-details', visible: true)
    page.assert_selector('.report-table tr:first-child .advance-details h3', text: I18n.t('reports.pages.advances_detail.record_title', advance_number: @advance_number), visible: true)
    remove_instance_variable(:@advance_number)
  end
end

When(/^I click on the hide link for the first advance detail view$/) do
  skip_if_table_empty do
    page.find('.report-table tr:first-child .advance-details .hide-detail-view').click
  end
end

Then(/^I should not see the detailed view for the first advance$/) do
  skip_if_table_empty do
    page.assert_selector('.report-table tr:first-child .advance-details', visible: :hidden)
  end
end

def check_advances_details_for_date(date)
  page.assert_selector('.report-summary-data h3', text: I18n.t('reports.pages.advances_detail.total_current_par_heading', date: date.strftime('%B %-d, %Y')))
  report_dates_in_range?((Time.zone.now.to_date - 100.years), date)
end