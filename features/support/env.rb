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
  require 'open3'
  require ::File.expand_path('../../../config/environment',  __FILE__)
  require 'capybara/rails'
  require 'net/ping/tcp'
  require_relative '../../api/mapi'

  Capybara.app = Rack::Builder.new do
    map '/' do
      run Capybara.app
    end
    map '/mapi' do
      run MAPI::ServiceApp
    end
  end.to_app

  def find_available_port
    server = TCPServer.new('127.0.0.1', 0)
    server.addr[1]
  ensure
    server.close if server
  end

  ldap_root = Rails.root.join('tmp', "openldap-data-#{Process.pid}")
  ldap_port = find_available_port
  ldap_server = File.expand_path('../../../ldap/run-server',  __FILE__) + " --port #{ldap_port} --root-dir #{ldap_root}"
  ldap_stdin, ldap_stdout, ldap_stderr, ldap_thr = Open3.popen3(ldap_server)
  ldap_ping = Net::Ping::TCP.new 'localhost', ldap_port, 1
  now = Time.now
  while !ldap_ping.ping
    if Time.now - now > 10
      raise "LDAP failed to start"
    end
    sleep(1)
  end

  # we close the LDAP server's STDIN and STDOUT immediately to avoid a ruby buffer depth issue.
  ldap_stdout.close
  ldap_stderr.close
  puts "LDAP Started: localhost:#{ldap_thr.pid}"
  at_exit do
    Process.kill('INT', ldap_thr.pid) rescue Errno::ESRCH
    ldap_stdin.close
    ldap_thr.value # wait for the thread to finish
    FileUtils.rm_rf(ldap_root)
  end

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
end

AfterStep('@pause') do
  print 'Press Return to continue'
  STDIN.getc
end
