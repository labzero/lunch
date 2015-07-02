class MemberSignersAndUsersJob < FhlbJob
  queue_as :high_priority

  def perform(member_id)
    results = MembersService.new(ActionDispatch::TestRequest.new).signers_and_users(member_id)

    raise 'There has been an error and MembersService#signers_and_users has encountered nil. Check error logs.' if results.nil?
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
