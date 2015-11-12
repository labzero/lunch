class MemberBalanceTodaysCreditActivityJob < FhlbJob
  queue_as :high_priority

  def perform(member_id)
    results = MemberBalanceService.new(member_id, ActionDispatch::TestRequest.new).todays_credit_activity

    raise 'There has been an error and MemberBalanceService#todays_credit_activity has encountered nil. Check error logs.' if results.nil?
    return if job_status.canceled?

    file = StringIOWithFilename.new(results.to_json)
    file.content_type = 'application/json'
    file.original_filename = "results.json"
    return if job_status.canceled?

    job_status.result = file
    job_status.status = :completed
    job_status.no_download = true
    job_status.save!
    results
  end
end
