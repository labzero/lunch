class MemberBalanceTodaysCreditActivityJob < FhlbJsonResponseJob
  queue_as :high_priority

  def perform(member_id)
    sleep 5 unless Rails.env.production? # to mimic slower load time when using real data
    MemberBalanceService.new(member_id, ActionDispatch::TestRequest.new).todays_credit_activity
  end
end
