require 'dotenv'
Dotenv.load

require 'capybara/rspec'
require 'capybara/cucumber'

require_relative 'custom_config'
include CustomConfig

require 'i18n'
I18n.load_path += Dir.glob('config/locales/*.yml')

require 'active_support/all'
Time.zone = ENV['TIMEZONE'] || 'Pacific Time (US & Canada)'

is_parallel_primary = ENV['TEST_ENV_NUMBER'] == ''
is_parallel_secondary = ENV['TEST_ENV_NUMBER'] && ENV['TEST_ENV_NUMBER'].length > 0
is_parallel = is_parallel_primary || is_parallel_secondary

custom_host = ENV['APP_HOST'] || env_config['app_host']

if is_parallel_secondary && !custom_host
  now = Time.now
  while !File.exists?('cucumber-primary-ready')
    if Time.now - now > 30
      raise "Cucumber runner #{ENV['TEST_ENV_NUMBER']} timed out waiting for the primary runner to start!"
    end
    sleep(1)
  end
end

if !custom_host
  ENV['RAILS_ENV'] ||= 'test' # for some reason we default to development in some cases
  ENV['RACK_ENV'] ||= 'test'

  require 'open3'
  require ::File.expand_path('../../../config/environment',  __FILE__)
  require 'capybara/rails'
  require 'net/ping/tcp'

  WebMock.allow_net_connect! # allow all Net connections

  AfterConfiguration do
    DatabaseCleaner.clean_with :truncation if !is_parallel || is_parallel_primary
  end

  def find_available_port
    server = TCPServer.new('127.0.0.1', 0)
    server.addr[1]
  ensure
    server.close if server
  end

  def check_service(port, thr, out, err, name=nil, host='127.0.0.1')
    name ||= "#{host}:#{port}"
    pinger = Net::Ping::TCP.new host, port, 1
    now = Time.now
    while !pinger.ping
      if Time.now - now > 10
        if ENV['VERBOSE']
          out.autoclose = false
          err.autoclose = false
          Process.kill('INT', thr.pid) rescue Errno::ESRCH
          thr.value
          IO.copy_stream(out, STDOUT)
          IO.copy_stream(err, STDERR)
        end
        out.close
        err.close
        raise "#{name} failed to start"
      end
      sleep(1)
    end
  end

  ldap_root = Rails.root.join('tmp', "openldap-data-#{Process.pid}")
  ldap_port = find_available_port
  ldap_server = File.expand_path('../../../ldap/run-server',  __FILE__) + " --port #{ldap_port} --root-dir #{ldap_root}"
  if ENV['VERBOSE']
    ldap_server += ' --verbose'
  end
  puts "LDAP starting, ldap://localhost:#{ldap_port}"
  ldap_stdin, ldap_stdout, ldap_stderr, ldap_thr = Open3.popen3(ldap_server)
  at_exit do
    Process.kill('INT', ldap_thr.pid) rescue Errno::ESRCH
    ldap_stdin.close
    ldap_thr.value # wait for the thread to finish
    FileUtils.rm_rf(ldap_root)
  end
  check_service(ldap_port, ldap_thr, ldap_stdout, ldap_stderr, 'LDAP')

  # we close the LDAP server's STDIN and STDOUT immediately to avoid a ruby buffer depth issue.
  ldap_stdout.close
  ldap_stderr.close
  puts 'LDAP Started.'

  puts `#{ldap_server} --reseed`
  ENV['LDAP_PORT'] = ldap_port.to_s

  mapi_port = find_available_port
  puts "Starting MAPI: http://localhost:#{mapi_port}"
  mapi_server = "rackup --port #{mapi_port} #{File.expand_path('../../../api/config.ru', __FILE__)}"
  mapi_stdin, mapi_stdout, mapi_stderr, mapi_thr = Open3.popen3({'RACK_ENV' => 'test'}, mapi_server)

  at_exit do
    Process.kill('INT', mapi_thr.pid) rescue Errno::ESRCH
    mapi_stdin.close
    mapi_thr.value # wait for the thread to finish
  end
  check_service(mapi_port, mapi_thr, mapi_stdout, mapi_stderr, 'MAPI')

  # we close the MAPI server's STDIN and STDOUT immediately to avoid a ruby buffer depth issue.
  mapi_stdout.close
  mapi_stderr.close
  puts 'MAPI Started.'
  ENV['MAPI_ENDPOINT'] = "http://localhost:#{mapi_port}/mapi"

  verbose = ENV['VERBOSE'] # Need to remove the VERBOSE env variable due to a conflict with Resque::VerboseFormatter and ActiveJob logging
  begin
    ENV.delete('VERBOSE')
    puts "Starting resque-pool..."
    resque_pool = "resque-pool -i"
    resque_stdin, resque_stdout, resque_stderr, resque_thr = Open3.popen3({'RAILS_ENV' => ENV['RAILS_ENV'] || ENV['RACK_ENV'], 'TERM_CHILD' => '1'}, resque_pool)
  ensure
    ENV['VERBOSE'] = verbose # reset the VERBOSE env variable after resque process is finished.
  end

  at_exit do
    Process.kill('TERM', resque_thr.pid) rescue Errno::ESRCH
    resque_stdin.close
    resque_thr.value # wait for the thread to finish
  end

  sleep 5
  unless resque_thr.alive?
    IO.copy_stream(resque_stdout, STDOUT)
    IO.copy_stream(resque_stderr, STDERR)
    raise 'resque-pool failed to start'
  end

  # we close the resque-pool's STDIN and STDOUT immediately to avoid a ruby buffer depth issue.
  resque_stdout.close
  resque_stderr.close
  puts 'resque-pool Started.'


else
  Capybara.app_host = custom_host
end

puts "Capybara.app_host: #{Capybara.app_host}"

AfterConfiguration do
  if Capybara.app_host.nil?
    Capybara.app_host = "#{Capybara.app_host || ('http://' + Capybara.current_session.server.host)}:#{Capybara.server_port || (Capybara.current_session.server ? Capybara.current_session.server.port : false) || 80}"
  end
  Rails.configuration.mapi.endpoint = ENV['MAPI_ENDPOINT'] unless custom_host
  url = Capybara.app_host
  puts url
  result = nil
  10.times do |i|
    result = %x[curl -w "%{http_code}" -m 3 -sL #{url} -o /dev/null]
    if result == '200'
      break
    end
    wait_time = ENV['WAIT_TIME'] ? ENV['WAIT_TIME'].to_i : 3
    puts "App not serving heartbeat (#{url})... waiting #{wait_time}s (#{i + 1} tr"+(i==0 ? "y" : "ies")+")"
    sleep wait_time
  end
  raise 'Server failed to serve heartbeat' if result != '200'
  sleep 10 #sleep 10 more seconds after we get our first 200 response to let the app come up more
  if !is_parallel || is_parallel_primary
    require Rails.root.join('db', 'seeds.rb') unless custom_host
  end

  if is_parallel_primary
    FileUtils.touch('cucumber-primary-ready')
    at_exit do
      FileUtils.rm_rf('cucumber-primary-ready')
    end
    sleep(20) # primary runner needs to sleep to make sure secondary workers see the sentinel (in the case where the primary work exits quickly... ie no work to do)
  end
end

AfterStep('@pause') do
  print 'Press Return to continue'
  STDIN.getc
end

if ENV['CUCUMBER_INCLUDE_SAUCE_SESSION']
  Around do |scenario, block|
    JenkinsSauce.output_jenkins_log(scenario)
    block.call
    ::Capybara.current_session.driver.quit if ENV['CUCUMBER_INCLUDE_SAUCE_SESSION'] == 'scenario'
  end
end
