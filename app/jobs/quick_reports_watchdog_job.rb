class QuickReportsWatchdogJob < FhlbJob
  queue_as :high_priority

  POLLING_INTERVAL = 10.seconds.freeze
  TIMEOUT = 10.minutes.freeze

  def perform(member_ids, _period=QuickReportSet.current_period)
    get_start_time
    self.period = _period
    self.total = member_ids.sum { |id| Member.new(id).quick_report_list.size }
    self.completed = 0
    self.last_completed_at = get_start_time
    self.long_run_threshold = get_start_time.end_of_day
    next_poll_at = get_start_time + POLLING_INTERVAL
    while !done? do
      if long_run?
        self.long_run_threshold = nil # stop checking for long runs
        InternalMailer.quick_report_long_run(completed, total).deliver_now
      end
      sleep_until(next_poll_at)
      next_poll_at += POLLING_INTERVAL
    end
    InternalMailer.quick_report_status(get_start_time, Time.zone.now, completed, total).deliver_now
  end

  protected

  attr_accessor :completed, :last_completed_at, :total, :period, :long_run_threshold

  def get_start_time
    @start_time ||= Time.zone.now
  end

  def done?
    batch_completed? || stalled?
  end

  def batch_completed?
    last_completed_count = completed
    self.completed = QuickReport.for_period(period).completed.count
    self.last_completed_at = Time.zone.now if completed != last_completed_count
    completed >= total
  end

  def stalled?
    Time.zone.now > last_completed_at + TIMEOUT
  end

  def long_run?
    !!long_run_threshold && Time.zone.now > long_run_threshold
  end

  def sleep_until(time)
    interval = time - Time.zone.now
    sleep(interval) if interval > 0
  end
end