class CalendarService < MAPIService

  def holidays(start_date, end_date)
    Rails.cache.fetch(CacheConfiguration.key(:calendar_holidays), expires_in: CacheConfiguration.expiry(:calendar_holidays)) do
      holidays = get_hash(:holidays, "calendar/holidays/#{start_date.iso8601}/#{end_date.iso8601}").try(:[], :holidays)
      raise StandardError, 'There has been an error and CalendarService#holidays has encountered nil. Check error logs.' if holidays.nil?
      holidays
    end
  end

end