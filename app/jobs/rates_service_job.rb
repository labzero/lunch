class RatesServiceJob < FhlbJsonResponseJob
  queue_as :high_priority

  def perform(method, uuid = nil, user_id = nil, *args)
    uuid ||= job_id
    service = RatesService.new(ActionDispatch::TestRequest.new)
    service.connection_request_uuid = uuid
    service.connection_user_id = user_id
    service.send(method.to_sym, *args)
  end
end