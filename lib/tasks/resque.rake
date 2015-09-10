require 'resque/pool/tasks'
# this task will get called before resque:pool:setup
# and preload the rails environment in the pool manager
task "resque:setup" => :environment do
  Resque.after_fork do |job|
    Rails.logger.info("Resque worker #{job.worker} forked for job: #{job.inspect}")
  end
end
task "resque:pool:setup" do
  Rails.logger.info("Starting resque-pool on #{`hostname`.strip} (#{Process.pid}).")
  # close any sockets or files in pool manager
  ActiveRecord::Base.connection.disconnect!
  # and re-open them in the resque worker parent
  Resque::Pool.after_prefork do
    WebMock.allow_net_connect! if Rails.env.test? # allow all Net connections
    ActiveRecord::Base.establish_connection
    Resque.redis.client.reconnect
    Rails.logger.info("Started Resque::Worker (#{Process.pid}) with connection: #{ActiveRecord::Base.connection}")
  end
end