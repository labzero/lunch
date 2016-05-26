class ProcessQuickReportsJob < FhlbJob
  queue_as :low_priority

  def perform(period=nil)
    period ||= QuickReportSet.current_period
    members = MembersService.new(ActionDispatch::TestRequest.new({'action_dispatch.request_id' => job_id})).all_members
    raise RuntimeError.new("failed to fetch member list for job: #{job_id}") unless members
    QuickReportsWatchdogJob.perform_later(members, period)
    members.collect {|m| Member.new(m[:id])}.each do |member|
      report_set = member.report_set_for_period(period)
      MemberProcessQuickReportsJob.perform_later(member.id, period) unless report_set.completed?
    end
  end

end