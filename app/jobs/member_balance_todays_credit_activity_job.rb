class MemberBalanceTodaysCreditActivityJob < FhlbJsonResponseJob
  queue_as :high_priority

  def perform(member_id, uuid = nil)
    request = ActionDispatch::TestRequest.new({'action_dispatch.request_id' => uuid})
    MemberBalanceService.new(member_id, request).todays_credit_activity
  end
end
