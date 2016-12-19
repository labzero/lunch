class MemberBalanceRecentCreditActivityJob < FhlbJsonResponseJob
  queue_as :high_priority

  def perform(member_id, uuid = nil)
    request = ActionDispatch::TestRequest.new({'action_dispatch.request_id' => uuid})
    member_balance_service = MemberBalanceService.new(member_id, request)
    todays_credit_activity = member_balance_service.todays_credit_activity
    historic_credit_activity = member_balance_service.historic_credit_activity
    if todays_credit_activity && historic_credit_activity
      (todays_credit_activity + historic_credit_activity).uniq{ |activity| activity['transaction_number']}
    else
      job_status.failed!
      nil
    end
  end
end
