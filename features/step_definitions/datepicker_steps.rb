require 'action_view'
require_relative '../../app/helpers/date_picker_helper'
include DatePickerHelper

When(/^I click the datepicker field$/) do
  page.find('.datepicker-trigger').click
end

Then(/^I should see the datepicker$/) do
  page.assert_selector('.daterangepicker', visible: true)
end

Then(/^I should see the datepicker preset for "(.*?)"$/) do |preset|
  text = get_datepicker_preset_label(preset)
  page.assert_selector('.ranges li', text: text)
end

Then(/^I should not see the datepicker preset for "(.*?)"$/) do |preset|
  page.assert_no_selector('.ranges li', text: preset)
end

When(/^I choose the "(.*?)" preset in the datepicker$/) do |preset|
  text = get_datepicker_preset_label(preset)
  page.first('.daterangepicker .ranges li', text: text).click
end

Then(/^I should see the end of the last full month as the default datepicker option$/) do
  today = Time.zone.today
  last_month = (today - 1.month).end_of_month.strftime("%B")
  text = today == today.end_of_month ? I18n.t('global.today') : I18n.t('datepicker.single.end_of', date: last_month)
  page.assert_selector('li.active', text: text)
end

When(/^I click the datepicker apply button$/) do
  page.find('.daterangepicker button', text: I18n.t('global.apply').upcase, visible: true).click
end

When(/^I click the datepicker cancel button$/) do
  page.find('.daterangepicker button.cancelBtn', visible: true).click
end

Then(/^I should see two calendars$/) do
  page.assert_selector('.daterangepicker .calendar.first', visible: true)
  page.assert_selector('.daterangepicker .calendar.second', visible: true)
end

Then(/^I should see no calendar$/) do
  page.assert_selector('.daterangepicker .calendar.first', visible: false)
  page.assert_selector('.daterangepicker .calendar.second', visible: false)
end

When(/^I select the (\d+)(?:st|rd|th) of "(.*?)" in the (left|right|single datepicker) calendar/) do |day, month, calendar|
  if calendar == 'single datepicker'
    calendar = page.find(".daterangepicker .calendar.single")
  else
    calendar = page.find(".daterangepicker .calendar.#{calendar}")
  end
  change_datepicker_to_month(@today, month, calendar)
  calendar.find("td.available:not(.off)", text: /^#{day}$/).click
end

When(/^I select a start date of "(.*?)" and an end date of "(.*?)"$/) do |start_date, end_date|
  start_date = start_date.to_date
  end_date = end_date.to_date
  step %{I select the #{start_date.strftime('%-d')}th of "#{start_date.strftime("%b %Y")}" in the left calendar}
  step %{I select the #{end_date.strftime('%-d')}th of "#{end_date.strftime("%b %Y")}" in the right calendar}
end

When(/^I select all of last year including today$/) do
  step 'I choose the "month to date preset" in the datepicker'
  calendar = page.find(".daterangepicker .calendar.left")
  day = @today.day
  target_month = (@today - 1.year).strftime("%b %Y")
  while calendar.find('.month').text != target_month
    calendar.find('.fa-arrow-left').click
  end
  calendar.find("td.available:not(.off)", text: /^#{day}$/).click
end

Then(/^I should see a report with dates for "(.*?)"$/) do |selector|
  step 'I wait for the report to load'
  case selector
    when 'month to date'
      start_date = default_dates_hash[:this_month_start]
      end_date = default_dates_hash[:today]
    when 'last month'
      start_date = default_dates_hash[:last_month_start]
      end_date = default_dates_hash[:last_month_end]
    when 'last year'
      start_date = default_dates_hash[:last_year_start]
      end_date = default_dates_hash[:last_year_end]
    else
      raise 'unknown date selector'
  end
  report_dates_in_range?(start_date, end_date)
end

Then(/^I should not see available dates after the most recent business day not including today/) do
  max_allowed_date = most_recent_business_day(@today - 1.day)
  if max_allowed_date.month == @today.month
    calendar = page.find(".daterangepicker .calendar.single")
    change_datepicker_to_month(@today, @today.strftime("%b %Y"), calendar)
    day = @today.mday
    calendar.assert_no_selector('.table-condensed .next.available')
    days = Time.days_in_month(@today.month, @today.year)
    (day + 1).upto(days) do |a_day|
      calendar.assert_selector("td.disabled.off", text: /^#{a_day}$/)
    end
  else
    # handles the case where the max allowed date occurs in the last calendar month
    page.assert_no_selector('.fa-arrow-right')
  end
end

When(/^I write "(.*?)" in the datepicker (start|end) input field$/) do |date, input|
  page.fill_in("daterangepicker_#{input}", with: ' ') # Capybara doesn't always clear input
  page.fill_in("daterangepicker_#{input}", with: date.to_s)
end

When(/^I write (today|tomorrow)'s date in the datepicker end input field$/) do |day|
  today = Time.zone.today
  time = case day
    when 'today'
      today
    when 'tomorrow'
      today + 1.day
    else
      raise 'Unknown day given as argument'
  end
  page.fill_in('daterangepicker_end', with: ' ') # Capybara doesn't always clear input
  page.fill_in('daterangepicker_end', with: time.strftime('%_m/%-d/%Y'))
end

When(/^I write a date from one month ago in the datepicker start input field$/) do
  date = Time.zone.today - 1.month
  page.fill_in('daterangepicker_start', with: ' ') # Capybara doesn't always clear input
  page.fill_in('daterangepicker_start', with: date.strftime('%_m/%-d/%Y'))
end

When(/^I write tomorrow's date in the datepicker start input field$/) do
  date = Time.zone.today + 1.day
  page.fill_in('daterangepicker_start', with: ' ') # Capybara doesn't always clear input
  page.fill_in('daterangepicker_start', with: date.strftime('%_m/%-d/%Y'))
end

When(/^that today's date is the (last day of last month|first day of this month)$/) do |date|
  today = Time.zone.today
  date = if date == 'last day of last month'
           (today - 1.month).end_of_month
         else
           today.beginning_of_month
         end
  step %{that today's date is "#{date}"}
end

When(/^that today's date is the (last day of last quarter|first day of this quarter)$/) do |date|
  date = if date == 'last day of last quarter'
           quarter_start_and_end_dates(last_quarter[:quarter], last_quarter[:year])[:end_date]
         else
           quarter_start_and_end_dates(current_quarter[:quarter], current_quarter[:year])[:start_date]
         end
  step %{that today's date is "#{date}"}
end

When(/^that today's date is "(.*?)"$/) do |date|
  now = Time.zone.now
  today = date.to_datetime.change(hour: now.hour, min: now.min, sec: now.sec)
  Timecop.travel(today)
end

def get_datepicker_preset_label(preset)
  case preset
    when 'month to date'
      I18n.t('datepicker.range.date_to_current', date: default_dates_hash[:this_month_start].to_date.strftime('%B'))
    when 'last month'
      default_dates_hash[:last_month_start].to_date.strftime('%B')
    when 'last year'
      default_dates_hash[:last_year_start].year.to_s
    else
      raise 'unknown preset for date picker'
  end
end

def change_datepicker_to_month(today, month, calendar)
  month = if month == 'this month'
            today.strftime("%b %Y")
          elsif month == 'last month'
            (today - 1.month).strftime("%b %Y")
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
end

def datepicker_ranged?
  page.all('.datepicker_input_field').count == 2
end

def datepicker_monthly?
  page.all('.datepicker-wrapper[data-date-picker-filter=endOfMonth]').present?
end

When(/^I click on the datepicker (start|end) input field$/) do |input|
  page.find("input[name=daterangepicker_#{input}]").click
end

Then(/^I should see the date "(.*?)" in the datepicker (start|end) input field/) do |date, input|
  page.find("input[name=daterangepicker_#{input}]").value.should eq date
end

When(/^I click on the datepicker field label$/) do
  page.all('.datepicker_input_field label').first.click
end

Then(/^I am able to enter two\-digit years in the datepicker inputs?$/) do
  datepicker_wrapper = page.find('.datepicker-wrapper')
  min_date = (datepicker_wrapper['data-date-picker-min-date'] || '1998-01-01').to_date
  max_date = (datepicker_wrapper['data-date-picker-max-date'] || Time.zone.today).to_date

  if datepicker_monthly?
    min_date = min_date.end_of_month
    max_date = max_date.end_of_month == max_date ? max_date : (max_date - 1.month).end_of_month
  end

  min_date_two_digit = min_date.strftime('%-m/%-d/%y')
  min_date_four_digit = min_date.strftime('%m/%d/%Y')
  max_date_two_digit = max_date.strftime('%-m/%-d/%y')
  max_date_four_digit = max_date.strftime('%m/%d/%Y')
  existing_start_date = page.find("input[name=daterangepicker_start]").value
  invalid_date = '1/32'

  step %{I write "#{min_date_two_digit}" in the datepicker start input field}
  step %{I click on the datepicker field label}
  step %{I should see the date "#{min_date_four_digit}" in the datepicker start input field}
  step %{I write "#{max_date_two_digit}" in the datepicker start input field}
  step %{I click on the datepicker field label}
  step %{I should see the date "#{max_date_four_digit}" in the datepicker start input field}
  step %{I write "#{invalid_date}" in the datepicker start input field}
  step %{I click on the datepicker field label}
  step %{I should see the date "#{existing_start_date}" in the datepicker start input field}

  if datepicker_ranged?
    existing_end_date = page.find("input[name=daterangepicker_end]").value
    step %{I write "#{min_date_two_digit}" in the datepicker end input field}
    step %{I click on the datepicker field label}
    step %{I should see the date "#{min_date_four_digit}" in the datepicker end input field}
    step %{I write "#{max_date_two_digit}" in the datepicker end input field}
    step %{I click on the datepicker field label}
    step %{I should see the date "#{max_date_four_digit}" in the datepicker end input field}
    step %{I write "#{invalid_date}" in the datepicker end input field}
    step %{I click on the datepicker field label}
    step %{I should see the date "#{existing_end_date}" in the datepicker end input field}
  end
end

Then(/^I am not able to enter prohibited characters in the datepicker inputs?$/) do
  step %{I write "a1b/c1d/ffff2011qwertyuiopasdfghjkl;zxcvbnm,.!@#$%^&*()_+" in the datepicker start input field}
  step %{I should see the date "1/1/2011" in the datepicker start input field}
  if datepicker_ranged?
    step %{I write "qwertyuiopasdfghjkl;zxcvbnm,.!@#$%^&*()_+a1b/c1d/ffff2011" in the datepicker end input field}
    step %{I should see the date "1/1/2011" in the datepicker end input field}
  end
end

When(/^I choose the (first|last) available date$/) do |position|
  available_dates = page.all('td.available:not(.off)', visible: true)
  i = 0
  while available_dates.blank? && i < 12 do
    page.find('.fa-arrow-right', visible: true).click
    available_dates = page.all('td.available:not(.off)', visible: true)
    i += 1
  end
  available_dates.send(:"#{position}").click unless available_dates.blank?
end

Then(/^I should see that weekends have been disabled$/) do
  page.assert_selector('.calendar tbody td.off.disabled:first-child, .calendar tbody td.off.disabled:last-child', visible: true)
  page.assert_no_selector('.calendar tbody td.available:first-child, .calendar tbody td.available:last-child', visible: true)
end

Then(/^I should see that all past dates have been disabled$/) do
  today = Time.zone.today
  target_month = today.strftime("%b %Y")
  calendar = page.find('.daterangepicker .calendar.single', visible: true)
  while calendar.find('.month').text != target_month
    calendar.find('.fa-arrow-left').click
  end
  page.assert_no_selector('.fa-arrow-left', visible: true)
  expect(page.all('td.available:not(.off)', visible: true).first.text.to_i).to be >= today.day
end

Then(/^I should not be able to see a calendar more than (\d+) months in the future$/) do |count|
  today = Time.zone.today
  target_month = (today + count.to_i.months).strftime("%b %Y")
  calendar = page.find('.daterangepicker .calendar.single', visible: true)
  while calendar.find('.month').text != target_month
    calendar.find('.fa-arrow-right').click
  end
  page.assert_no_selector('.fa-arrow-right', visible: true)
end