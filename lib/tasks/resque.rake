require 'resque/pool/tasks'
# this task will get called before resque:pool:setup
# and preload the rails environment in the pool manager
task "resque:setup" => :environment do
  # generic worker setup, e.g. Hoptoad for failed jobs
end
task "resque:pool:setup" do
  # close any sockets or files in pool manager
  ActiveRecord::Base.connection.disconnect!
  # and re-open them in the resque worker parent
  Resque::Pool.after_prefork do |job|
    WebMock.allow_net_connect! if Rails.env.test? # allow all Net connections
    ActiveRecord::Base.establish_connection
    Resque.redis.client.reconnect
  end
end