require 'dotenv'
Dotenv.load

require 'capybara/rspec'
require 'capybara/cucumber'

require_relative 'custom_config'
include CustomConfig

require 'i18n'
I18n.load_path += Dir.glob('config/locales/*.yml')

custom_host = ENV['APP_HOST'] || env_config['app_host']

if !custom_host
  require ::File.expand_path('../../../config/environment',  __FILE__)
  require 'capybara/rails'
else
  Capybara.app_host = custom_host
end

puts "Capybara.app_host: #{Capybara.app_host}"

AfterConfiguration do
  if Capybara.app_host.nil?
    Capybara.app_host = "#{Capybara.app_host || ('http://' + Capybara.current_session.server.host)}:#{Capybara.server_port || (Capybara.current_session.server ? Capybara.current_session.server.port : false) || 80}"
  end
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
