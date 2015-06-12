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

When(/^I choose the "(.*?)" preset in the datepicker$/) do |preset|
  text = get_datepicker_preset_label(preset)
  page.first('.daterangepicker .ranges li', text: text).click
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

Then(/^I should see a report with dates for "(.*?)"$/) do |selector|
  case selector
    when 'month to date'
      start_date = default_dates_hash[:this_month_start]
      end_date = default_dates_hash[:today]
    when 'last month'
      start_date = default_dates_hash[:last_month_start]
      end_date = default_dates_hash[:last_month_end]
    when 'current quarter to date'
      start_date = quarter_start_and_end_dates((current_quarter[:quarter]), current_quarter[:year])[:start_date]
      end_date = default_dates_hash[:today]
    when 'last quarter'
      start_date = quarter_start_and_end_dates(last_quarter[:quarter], last_quarter[:year])[:start_date]
      end_date = quarter_start_and_end_dates(last_quarter[:quarter], last_quarter[:year])[:end_date]
    when 'year to date'
      start_date = default_dates_hash[:this_year_start]
      end_date = default_dates_hash[:today]
    when 'last year'
      start_date = default_dates_hash[:last_year_start]
      end_date = default_dates_hash[:last_year_end]
    else
      raise 'unknown date selector'
  end
  report_dates_in_range?(start_date, end_date)
end

Then(/^I should not see available dates after today$/) do
  step %{I choose the "custom date" preset in the datepicker}
  calendar = page.find(".daterangepicker .calendar.single")
  change_datepicker_to_month(@today, @today.strftime("%b %Y"), calendar)
  day = @today.mday
  calendar.assert_no_selector('.table-condensed .next.available')
  days = Time.days_in_month(@today.month, @today.year)
  (day + 1).upto(days) do |a_day|
    calendar.assert_selector("td.disabled.off", text: /^#{a_day}$/)
  end
end

When(/^I write "(.*?)" in the datepicker (start|end) input field$/) do |date, input|
  page.fill_in("daterangepicker_#{input}", with: ' ') # Capybara doesn't always clear input
  page.fill_in("daterangepicker_#{input}", with: date.to_s)
end

def get_datepicker_preset_label(preset)
  case preset
    when 'month to date'
      I18n.t('datepicker.range.date_to_current', date: default_dates_hash[:this_month_start].to_date.strftime('%B'))
    when 'last month'
      default_dates_hash[:last_month_start].to_date.strftime('%B')
    when 'current quarter to date'
      I18n.t('datepicker.range.date_to_current', date: I18n.t("dates.quarters.#{current_quarter[:quarter]}", year: current_quarter[:year]))
    when 'last quarter'
      I18n.t("dates.quarters.#{last_quarter[:quarter]}", year: last_quarter[:year])
    when 'year to date'
      I18n.t('datepicker.range.date_to_current', date: default_dates_hash[:this_year_start].year)
    when 'last year'
      default_dates_hash[:last_year_start].year.to_s
    when 'custom date range'
      I18n.t('datepicker.range.custom')
    when 'custom date'
      I18n.t('datepicker.single.custom')
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