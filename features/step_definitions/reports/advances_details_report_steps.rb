include DatePickerHelper

Then(/^I should see advances details for last business day/) do
  check_advances_details_for_date(most_recent_business_day(Time.zone.now.to_date - 1.day))
end

Then(/^I should see advances details for the (\d+)(?:st|rd|th) of (this|last) month$/) do |day, month|
  step 'I wait for the report to load'
  today = Time.zone.now.to_date
  if month == 'this'
    date = Date.new(today.year, today.month, day)
  else
    last_month = today - 1.month
    date = Date.new(last_month.year, last_month.month, day.to_i)
  end
  check_advances_details_for_date(date)
end

def check_advances_details_for_date(date)
  page.assert_selector('.report-summary-data h3', text: strip_tags(report_summary_with_date('reports.pages.advances_detail.total_current_par_heading', date.strftime('%B %-d, %Y'))))
  report_dates_in_range?((Time.zone.now.to_date - 100.years), date)
end
