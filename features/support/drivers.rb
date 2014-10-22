require 'selenium/webdriver'

my_driver = (ENV['BROWSER'] && ENV['BROWSER'].to_sym) || :chrome
puts "my_driver:  #{my_driver}"

Capybara.default_driver = my_driver
Capybara.javascript_driver = my_driver

Capybara.register_driver :chrome do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome, :switches => %w[--disable-popup-blocking])
end

Capybara.register_driver :firefox do |app|
  Capybara::Selenium::Driver.new(app, :browser => :firefox)
end

SAUCE_USERNAME = ENV['SAUCE_USERNAME'] || 'TODO_REPLACE_ME'
SAUCE_ACCESS_KEY = ENV['SAUCE_ACCESS_KEY'] || 'TODO_REPLACE_ME'
SAUCE_PORT = ENV['SAUCE_ONDEMAND_PORT'] || '4445'

def sauce_build
  if ENV['REMOTE'] == 'true'
    "remote: #{ENV['APP_HOST'] || Capybara.app_host}"
  else
    `hostname`.strip
  end
end

def sauce_name
  ENV['JOB_NAME'] || "Local Dev (#{`whoami`.strip})"
end

base_opts = {:username => SAUCE_USERNAME, :access_key => SAUCE_ACCESS_KEY, :build => sauce_build, :name => sauce_name, :'parent-tunnel' => (ENV['SAUCE_PARENT_TUNNEL'] || nil)}

SAUCE_CONNECT_URL = ENV['REMOTE'] == 'true' ? "http://#{SAUCE_USERNAME}:#{SAUCE_ACCESS_KEY}@ondemand.saucelabs.com:80/wd/hub" : "http://localhost:#{SAUCE_PORT}/wd/hub"


Capybara.register_driver :sauce_ie_8_win7 do |app|
  caps = base_opts.merge({:platform => 'Windows 7', :version => '8'})

  Capybara::Selenium::Driver.new(app,
                                 :browser => :remote,
                                 :url => SAUCE_CONNECT_URL,
                                 :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.internet_explorer(caps))
end

Capybara.register_driver :sauce_ie_9_win7 do |app|
  caps = base_opts.merge({:platform => 'Windows 7', :version => '9'})

  Capybara::Selenium::Driver.new(app,
                                 :browser => :remote,
                                 :url => SAUCE_CONNECT_URL,
                                 :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.internet_explorer(caps))
end

Capybara.register_driver :sauce_ie_10_vista do |app|
  caps = base_opts.merge({:platform => 'vista', :version => '10'})

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

Capybara.register_driver :sauce_firefox_15_vista do |app|
  caps = base_opts.merge({:platform => 'vista', :version => '15'})

  Capybara::Selenium::Driver.new(app,
                                 :browser => :remote,
                                 :url => SAUCE_CONNECT_URL,
                                 :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.firefox(caps))
end

Capybara.register_driver :sauce_firefox_23_vista do |app|
  caps = base_opts.merge({:platform => 'vista', :version => '23'})

  Capybara::Selenium::Driver.new(app,
                                 :browser => :remote,
                                 :url => SAUCE_CONNECT_URL,
                                 :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.firefox(caps))
end

Capybara.register_driver :sauce_android_4_0 do |app|
  caps = base_opts.merge({:platform => 'linux', :version => '4.0'})

  Capybara::Selenium::Driver.new(app,
                                 :browser => :remote,
                                 :url => SAUCE_CONNECT_URL,
                                 :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.android(caps))
end

Capybara.register_driver :sauce_iphone_6 do |app|
  caps = base_opts.merge({:platform => 'OS X 10.8', :version => '6'})

  Capybara::Selenium::Driver.new(app,
                                 :browser => :remote,
                                 :url => SAUCE_CONNECT_URL,
                                 :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.iphone(caps))
end
