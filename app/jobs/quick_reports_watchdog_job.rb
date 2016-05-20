class QuickReportsWatchdogJob < FhlbJob
  queue_as :high_priority

  POLLING_INTERVAL = 10.seconds.freeze
  TIMEOUT = 10.minutes.freeze

  def perform(members, period=QuickReportSet.current_period)
    get_start_time
    total = members.sum { |member| member.quick_report_list.size }
    completed = 0
    loop do
      break if (completed = QuickReportSet.for_period(period).completed.count) >= total
      now = Time.zone.now
      break if now > get_start_time + TIMEOUT
      adjusted_polling_interval = POLLING_INTERVAL - (now - get_start_time)
      sleep(adjusted_polling_interval > 0 ? adjusted_polling_interval : 0)
    end
    InternalMailer.quick_report_status(get_start_time, Time.zone.now, completed, total).deliver_now
  end

  protected

  def get_start_time
    @start_time ||= Time.zone.now
  end
end