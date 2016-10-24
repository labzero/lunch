class CalendarService < MAPIService

  def holidays(start_date, end_date)
    holidays_array = Rails.cache.fetch(CacheConfiguration.key(:calendar_holidays), expires_in: CacheConfiguration.expiry(:calendar_holidays)) do
      holidays = get_hash(:holidays, "calendar/holidays/#{start_date.iso8601}/#{end_date.iso8601}").try(:[], :holidays)
      raise StandardError, 'There has been an error and CalendarService#holidays has encountered nil. Check error logs.' if holidays.nil?
      holidays
    end
    holidays_array.map{ |holiday| holiday.to_date }
  end

  def find_next_business_day(candidate, delta)
    weekend_or_holiday?(candidate) ? find_next_business_day(candidate + delta, delta) : candidate
  end

  def weekend_or_holiday?(date)
    date.saturday? || date.sunday? || holidays(date, date).include?(date)
  end

end