require 'dotenv'
Dotenv.load

require 'capybara/rspec'
require 'capybara/cucumber'

require_relative 'custom_config'
include CustomConfig

require 'i18n'
I18n.load_path += Dir.glob('config/locales/*.yml')

require 'active_support/all'

custom_host = ENV['APP_HOST'] || env_config['app_host']

if !custom_host
  ENV['RAILS_ENV'] ||= 'test' # for some reason we default to development in some cases
  ENV['RACK_ENV'] ||= 'test'

  require 'open3'
  require ::File.expand_path('../../../config/environment',  __FILE__)
  require 'capybara/rails'
  require 'net/ping/tcp'
  require_relative '../../api/mapi'

  WebMock.allow_net_connect! # allow all Net connections

  Capybara.app = Rack::Builder.new do
    map '/' do
      run Capybara.app
    end
    map '/mapi' do
      run MAPI::ServiceApp
    end
  end.to_app

  AfterConfiguration do
    DatabaseCleaner.clean_with :truncation
  end

  Before('@clean') do
    DatabaseCleaner.clean_with :truncation
  end

  def find_available_port
    server = TCPServer.new('127.0.0.1', 0)
    server.addr[1]
  ensure
    server.close if server
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
    DatabaseCleaner.clean_with :truncation
  end
  ldap_ping = Net::Ping::TCP.new 'localhost', ldap_port, 1
  now = Time.now
  while !ldap_ping.ping
    if Time.now - now > 10
      if ENV['VERBOSE']
        ldap_stdout.autoclose = false
        ldap_stderr.autoclose = false
        Process.kill('INT', ldap_thr.pid) rescue Errno::ESRCH
        ldap_thr.value
        IO.copy_stream(ldap_stdout, STDOUT)
        IO.copy_stream(ldap_stderr, STDERR)
      end
      ldap_stdout.close
      ldap_stderr.close
      raise "LDAP failed to start"
    end
    sleep(1)
  end

  # we close the LDAP server's STDIN and STDOUT immediately to avoid a ruby buffer depth issue.
  ldap_stdout.close
  ldap_stderr.close
  puts 'LDAP Started.'

  puts `#{ldap_server} --reseed`
  ENV['LDAP_PORT'] = ldap_port.to_s
else
  Capybara.app_host = custom_host
end

puts "Capybara.app_host: #{Capybara.app_host}"

AfterConfiguration do
  if Capybara.app_host.nil?
    Capybara.app_host = "#{Capybara.app_host || ('http://' + Capybara.current_session.server.host)}:#{Capybara.server_port || (Capybara.current_session.server ? Capybara.current_session.server.port : false) || 80}"
  end
  Rails.configuration.mapi.endpoint = Capybara.app_host + '/mapi' unless custom_host
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
  require Rails.root.join('db', 'seeds.rb') unless custom_host
end

AfterStep('@pause') do
  print 'Press Return to continue'
  STDIN.getc
end
