require 'resque/pool/tasks'
require 'resque/scheduler/tasks'

namespace :resque do
  # this task will get called before resque:pool:setup
  # and preload the rails environment in the pool manager
  task :setup => :environment do
    Resque.before_fork do |job|
      ActiveRecord::Base.connection_pool.disconnect!
    end
    Resque.after_fork do |job|
      Rails.logger.info("Resque worker #{job.worker} forked (pid #{Process.pid}) for job: #{job.inspect}")
      ActiveRecord::Base.establish_connection
      # Switch into blocking mode for OCI8 as there are threading issues when used with the AWS S3 SDK
      # Reported at https://github.com/kubo/ruby-oci8/issues/86#issuecomment-140636099
      connection = ActiveRecord::Base.connection
      connection.raw_connection.non_blocking = false if connection.is_a? ActiveRecord::ConnectionAdapters::OracleEnhancedAdapter
    end
  end
  task "pool:setup" do
    Rails.logger.info("Starting resque-pool on #{`hostname`.strip} (#{Process.pid}).")
    # close any sockets or files in pool manager
    ActiveRecord::Base.connection.disconnect!
    # and re-open them in the resque worker parent
    Resque::Pool.after_prefork do
      WebMock.allow_net_connect! if Rails.env.test? # allow all Net connections
      Resque.redis.client.reconnect
      Rails.logger.info("Started Resque::Worker (#{Process.pid})")
    end
  end

  task :setup_schedule => :setup do
    require 'resque-scheduler'

    # If you want to be able to dynamically change the schedule,
    # uncomment this line.  A dynamic schedule can be updated via the
    # Resque::Scheduler.set_schedule (and remove_schedule) methods.
    # When dynamic is set to true, the scheduler process looks for
    # schedule changes and applies them on the fly.
    # Note: This feature is only available in >=2.0.0.
    # Resque::Scheduler.dynamic = true

    # The schedule doesn't need to be stored in a YAML, it just needs to
    # be a hash.  YAML is usually the easiest.
    schedule = YAML.load(ERB.new(File.read(Rails.root.join('config', 'schedule.yml'))).result) || {}
    override_file = Rails.root.join('config', 'schedule-override.yml')
    schedule.merge!(YAML.load(ERB.new(File.read(override_file)).result) || {}) if File.size?(override_file)
    Resque.schedule = schedule
  end

  task :scheduler => :setup_schedule
end
