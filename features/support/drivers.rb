require 'selenium/webdriver'

my_driver = (ENV['BROWSER'] && ENV['BROWSER'].to_sym) || :chrome
puts "my_driver:  #{my_driver}"

Capybara.default_driver = my_driver
Capybara.javascript_driver = my_driver
Capybara.default_wait_time = 10

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome, :switches => %w[--disable-popup-blocking])
end

Capybara.register_driver :firefox do |app|
  Capybara::Selenium::Driver.new(app, :browser => :firefox)
end

SAUCE_USERNAME = ENV['SAUCE_USERNAME']
SAUCE_ACCESS_KEY = ENV['SAUCE_ACCESS_KEY']
SAUCE_PORT = ENV['SAUCE_ONDEMAND_PORT'] || '4445'

def sauce_build
  if ENV['REMOTE'] == 'true'
    "remote: #{ENV['APP_HOST'] || Capybara.app_host}"
  else
    `hostname`.strip
  end
end

def sauce_name
  [ENV['JOB_NAME'] || "Local Dev (#{`whoami`.strip})", ENV['BUILD_NUMBER'], ENV['TEST_ENV_NUMBER']].compact.join('-')
end

base_opts = {
  :username => SAUCE_USERNAME,
  :access_key => SAUCE_ACCESS_KEY,
  :build => sauce_build,
  :name => sauce_name,
  :'parent-tunnel' => ENV['SAUCE_PARENT_TUNNEL'],
  :'tunnel-identifier' => ENV['SAUCE_TUNNEL_IDENTIFIER'],
  :'selenium-version' => ENV['SAUCE_SELENIUM_VERSION'],
  :'iedriver-version' => ENV['SAUCE_IEDRIVER_VERSION'],
  :'screenResolution' =>  ENV['SAUCE_SCREEN_RESOLUTION'] || '1280x1024',
  :'maxDuration' => ENV['SAUCE_MAX_DURATION'] || 3600
}

SAUCE_CONNECT_URL = ENV['REMOTE'] == 'true' ? "http://#{SAUCE_USERNAME}:#{SAUCE_ACCESS_KEY}@ondemand.saucelabs.com:80/wd/hub" : "http://localhost:#{SAUCE_PORT}/wd/hub"


Capybara.register_driver :sauce_ie_9_win7 do |app|
  caps = base_opts.merge({:platform => 'Windows 7', :version => '9'})

  Capybara::Selenium::Driver.new(app,
                                 :browser => :remote,
                                 :url => SAUCE_CONNECT_URL,
                                 :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.internet_explorer(caps))
end

Capybara.register_driver :sauce_ie_10_win7 do |app|
  caps = base_opts.merge({:platform => 'Windows 7', :version => '10'})

  Capybara::Selenium::Driver.new(app,
                                 :browser => :remote,
                                 :url => SAUCE_CONNECT_URL,
                                 :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.internet_explorer(caps))
end

Capybara.register_driver :sauce_ie_11_win7 do |app|
  caps = base_opts.merge({:platform => 'Windows 7', :version => '11'})

  Capybara::Selenium::Driver.new(app,
                                 :browser => :remote,
                                 :url => SAUCE_CONNECT_URL,
                                 :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.internet_explorer(caps))
end

Capybara.register_driver :sauce_chrome_win7 do |app|
  caps = base_opts.merge({:platform => 'Windows 7'})
  Capybara::Selenium::Driver.new(app,
                                 :browser => :remote,
                                 :url => SAUCE_CONNECT_URL,
                                 :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.chrome(caps))
end

Capybara.register_driver :rack_test do |app|
  Capybara::RackTest::Driver.new(app, follow_redirects: true, respect_data_method: true)
end
