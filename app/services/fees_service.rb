class FeesService < MAPIService
  
  def fee_schedules
    get_hash(:fee_schedules, "fees/schedules")
  end
  
end