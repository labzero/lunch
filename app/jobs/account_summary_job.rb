class AccountSummaryJob < FhlbJsonResponseJob
  queue_as :high_priority

  def perform(member_id, uuid = nil)
    request = ActionDispatch::TestRequest.new({'action_dispatch.request_id' => uuid})
    {
      member_profile: MemberBalanceService.new(member_id, request).profile,
      member_details: MembersService.new(request).member(member_id)
    }
  end
end