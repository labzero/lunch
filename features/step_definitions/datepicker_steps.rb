When(/^I click the datepicker field$/) do
  page.find('.datepicker-trigger').click
end

Then(/^I should see the datepicker$/) do
  page.assert_selector('.daterangepicker', visible: true)
end

When(/^I choose the custom date range in the datepicker$/) do
  page.find('.daterangepicker .ranges li', text: I18n.t('datepicker.range.custom')).click
end

When(/^I choose the month to date preset in the datepicker$/) do
  page.find('.daterangepicker .ranges li', text: I18n.t('datepicker.range.this_month', month: @today.strftime("%B"))).click
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

When(/^I select the (\d+)(?:st|rd|th) of (this|last) month in the (left|right) calendar/) do |day, month, calendar|
  calendar = page.find(".daterangepicker .calendar.#{calendar}")
  month = if month == 'this'
            @today.strftime("%b %Y")
          elsif month == 'last'
            (@today - 1.month).strftime("%b %Y")
          end
  current_month = calendar.find('.month').text.to_date
  if current_month.year > @today.year
    advance_class = '.fa-arrow-left'
  else
    if current_month.year == @today.year && current_month.month > @today.month
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

When(/^I select all of last year including today$/) do
  step 'I choose the month to date preset in the datepicker'
  step  'I choose the custom date range in the datepicker'
  calendar = page.find(".daterangepicker .calendar.left")
  day = @today.day
  target_month = (@today - 1.year).strftime("%b %Y")
  while calendar.find('.month').text != target_month
    calendar.find('.fa-arrow-left').click
  end
  calendar.find("td.available:not(.off)", text: /^#{day}$/).click
end




