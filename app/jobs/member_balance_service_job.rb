class MemberBalanceServiceJob < FhlbJsonResponseJob
  queue_as :high_priority

  def perform(member_id, method, uuid = nil, *args)
    uuid ||= job_id
    request = ActionDispatch::TestRequest.new({'action_dispatch.request_id' => uuid})
    MemberBalanceService.new(member_id, request).send(method.to_sym, *args)
  end
end