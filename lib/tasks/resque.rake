require 'resque/pool/tasks'
# this task will get called before resque:pool:setup
# and preload the rails environment in the pool manager
task "resque:setup" => :environment do
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
task "resque:pool:setup" do
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