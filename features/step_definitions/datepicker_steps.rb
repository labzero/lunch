When(/^I click the datepicker field$/) do
  page.find('.datepicker-trigger').click
end

Then(/^I should see the datepicker$/) do
  page.assert_selector('.daterangepicker', visible: true)
end

When(/^I choose the "(.*?)" in the datepicker$/) do |selector|
  text = case selector
    when 'custom date range'
      I18n.t('datepicker.range.custom')
    when 'custom date'
      I18n.t('datepicker.single.custom')
    when 'month to date preset'
      I18n.t('datepicker.range.this_month', month: @today.strftime("%B"))
    when 'last year preset'
      I18n.t('global.last_year')
    else
      raise 'unknown selector for date picker'
  end
  page.find('.daterangepicker .ranges li', text: text).click
end

When(/^I click the datepicker apply button$/) do
  page.find('.daterangepicker button', text: I18n.t('global.apply').upcase, visible: true).click
end

Then(/^I should see two calendars$/) do
  page.assert_selector('.daterangepicker .calendar.first', visible: true)
  page.assert_selector('.daterangepicker .calendar.second', visible: true)
end

Then(/^I should see no calendar$/) do
  page.assert_selector('.daterangepicker .calendar.first', visible: false)
  page.assert_selector('.daterangepicker .calendar.second', visible: false)
end

When(/^I choose the last month preset in the datepicker$/) do
  page.find('.daterangepicker .ranges li', text: (@today.beginning_of_month - 1.months).strftime("%B")).click
end

When(/^I select the (\d+)(?:st|rd|th) of "(.*?)" in the (left|right|single datepicker) calendar/) do |day, month, calendar|
  if calendar == 'single datepicker'
    calendar = page.find(".daterangepicker .calendar.single")
  else
    calendar = page.find(".daterangepicker .calendar.#{calendar}")
  end
  month = if month == 'this month'
            @today.strftime("%b %Y")
          elsif month == 'last month'
            (@today - 1.month).strftime("%b %Y")
          else
            month
          end
  current_month = calendar.find('.month').text.to_date
  if current_month.year > month.to_date.year
    advance_class = '.fa-arrow-left'
  else
    if current_month.year == month.to_date.year && current_month.month > month.to_date.month
      advance_class = '.fa-arrow-left'
    else
      advance_class = '.fa-arrow-right'
    end
  end
  while calendar.find('.month').text != month
    calendar.find(advance_class).click
    # we should add a 5 second check here to avoid infinte loops
  end
  calendar.find("td.available:not(.off)", text: /^#{day}$/).click
end

When(/^I select a start date of "(.*?)" and an end date of "(.*?)"$/) do |start_date, end_date|
  start_date = start_date.to_date
  end_date = end_date.to_date
  step %{I select the 1st of "#{start_date.strftime("%b %Y")}" in the left calendar}
  step %{I select the 31st of "#{end_date.strftime("%b %Y")}" in the right calendar}
end

When(/^I select all of last year including today$/) do
  step 'I choose the "month to date preset" in the datepicker'
  step  'I choose the "custom date range" in the datepicker'
  calendar = page.find(".daterangepicker .calendar.left")
  day = @today.day
  target_month = (@today - 1.year).strftime("%b %Y")
  while calendar.find('.month').text != target_month
    calendar.find('.fa-arrow-left').click
  end
  calendar.find("td.available:not(.off)", text: /^#{day}$/).click
end

Then(/^I should see a report with dates for last year$/) do
  today = Time.zone.now.to_date
  last_year_start = (today - 1.year).beginning_of_year
  last_year_end = (today - 1.year).end_of_year
  report_dates_in_range?(last_year_start, last_year_end)
end
