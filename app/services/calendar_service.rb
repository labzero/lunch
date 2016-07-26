class CalendarService < MAPIService

  def holidays(start_date, end_date)
    get_hash(:holidays, "calendar/holidays/#{start_date.iso8601}/#{end_date.iso8601}").try(:[], :holidays)
  end

end