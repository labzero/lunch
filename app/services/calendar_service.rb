class CalendarService < MAPIService

  def holidays(start_date, end_date)
    holidays = get_hash(:holidays, "calendar/holidays/#{start_date.iso8601}/#{end_date.iso8601}").try(:[], :holidays)
    raise StandardError, 'There has been an error and CalendarService#holidays has encountered nil. Check error logs.' if holidays.nil?
    holidays.map{ |holiday| holiday.to_date }
  end

  def find_next_business_day(candidate, delta)
    weekend_or_holiday?(candidate) ? find_next_business_day(candidate + delta, delta) : candidate
  end

  def find_previous_business_day(candidate, delta)
    find_next_business_day(candidate, -delta)
  end

  def weekend_or_holiday?(date)
    date.saturday? || date.sunday? || holidays(date, date).include?(date)
  end

  def number_of_business_days(start_date, end_date)
    number_of_business_days = 0
    holidays = holidays(start_date, end_date)
    current_day = start_date + 1.day
    while (current_day <= end_date)
      number_of_business_days = number_of_business_days + 1 if (!current_day.saturday? && !current_day.sunday? && !holidays.include?(current_day))
      current_day = current_day + 1.day
    end
    number_of_business_days
  end

end