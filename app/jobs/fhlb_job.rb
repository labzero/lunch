class FhlbJob < ActiveJob::Base

  def initialize(*args, &block)
    # Run the alias method chain on the eigenclass to modify our subclasses perform. This should always be done first.
    class << self
      alias_method_chain :perform, :rescue
    end

    super
    @mutex = Mutex.new
  end

  def job_status
    @mutex.synchronize { @job_status ||= JobStatus.find_or_create_by!(job_id: self.job_id) } # cause we are BOSS
    @job_status
  end

  before_enqueue do |job|
    job.job_status # ensure that JobStatus instance has been created prior to enqueuing
  end

  def perform_with_rescue(*args, &block)
    return if job_status.canceled?
    job_status.started!
    result = perform_without_rescue(*args, &block)
    job_status.completed! unless job_status.completed? || job_status.canceled?
    result # return the result of the job to handle the case where job is executed inline
  rescue => err
    Rails.logger.warn "#{self.class.name}##{job_id} raised an exception: #{err}"
    Rails.logger.debug "BACKTRACE: #{err.backtrace.join("\n")}"
    job_status.failed!
  end

  def self.queue
    queue_name
  end

  def self.scheduled(queue, klass, *args)
    klass.constantize.set(queue: queue).perform_later(*args)
  end
end