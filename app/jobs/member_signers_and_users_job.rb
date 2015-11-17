class MemberSignersAndUsersJob < FhlbJsonResponseJob
  queue_as :high_priority

  def perform(member_id)
    MembersService.new(ActionDispatch::TestRequest.new).signers_and_users(member_id)
  end
end
