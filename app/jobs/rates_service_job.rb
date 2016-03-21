class RatesServiceJob < FhlbJsonResponseJob
  queue_as :high_priority

  def perform(method, uuid = nil, *args)
    uuid ||= job_id
    request = ActionDispatch::TestRequest.new({'action_dispatch.request_id' => uuid})
    RatesService.new(request).send(method.to_sym, *args)
  end
end