require 'selenium/webdriver'

my_driver = (ENV['BROWSER'] && ENV['BROWSER'].to_sym) || :chrome
puts "my_driver:  #{my_driver}"

if defined?(Capybara)
  Capybara.default_driver = my_driver
  Capybara.javascript_driver = my_driver
  Capybara.default_max_wait_time = 10

  if Capybara.default_driver =~ /safari/i
    safari_port = [2000, 2001, 2020, 2109, 2222, 2310, 3001, 3030,
      3210, 3333, 4000, 4001, 4040, 4321, 4502, 4503, 4567, 5000,
      5001, 5050, 5555, 5432, 6000, 6001, 6060, 6666, 6543, 7000,
      7070, 7774, 7777, 8000, 8001, 8003, 8031, 8081, 8765, 8777,
      8888, 9000, 9001, 9080, 9090, 9876, 9877, 9999, 49221, 55001
    ]
    Capybara.server_port = find_available_port(safari_port)
  end

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

  base_opts = {
    :username => SAUCE_USERNAME,
    :access_key => SAUCE_ACCESS_KEY,
    :build => sauce_build,
    :name => run_name,
    :'parent-tunnel' => ENV['SAUCE_PARENT_TUNNEL'],
    :'tunnel-identifier' => ENV['SAUCE_TUNNEL_IDENTIFIER'],
    :'selenium-version' => ENV['SAUCE_SELENIUM_VERSION'],
    :'iedriver-version' => ENV['SAUCE_IEDRIVER_VERSION'],
    :chromedriverVersion => ENV['SAUCE_CHROMEDRIVER_VERSION'],
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

  Capybara.register_driver :sauce_ie_10_win8 do |app|
    caps = base_opts.merge({:platform => 'Windows 8', :version => '10'})

    Capybara::Selenium::Driver.new(app,
                                   :browser => :remote,
                                   :url => SAUCE_CONNECT_URL,
                                   :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.internet_explorer(caps))
  end

  Capybara.register_driver :sauce_ie_11_win81 do |app|
    caps = base_opts.merge({:platform => 'Windows 8.1', :version => '11'})

    Capybara::Selenium::Driver.new(app,
                                   :browser => :remote,
                                   :url => SAUCE_CONNECT_URL,
                                   :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.internet_explorer(caps))
  end

  Capybara.register_driver :sauce_ie_11_win10 do |app|
    caps = base_opts.merge({:platform => 'Windows 10', :version => '11'})

    Capybara::Selenium::Driver.new(app,
                                   :browser => :remote,
                                   :url => SAUCE_CONNECT_URL,
                                   :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.internet_explorer(caps))
  end

  Capybara.register_driver :sauce_safari_9_osx_11 do |app|
    caps = base_opts.merge({:platform => 'OS X 10.11', :version => '9.0', :screenResolution => ENV['SAUCE_SCREEN_RESOLUTION'] || '1376x1032'})

    Capybara::Selenium::Driver.new(app,
                                   :browser => :remote,
                                   :url => SAUCE_CONNECT_URL,
                                   :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.safari(caps))
  end

  Capybara.register_driver :sauce_safari_8_osx_10 do |app|
    caps = base_opts.merge({:platform => 'OS X 10.10', :version => '8.0'})

    Capybara::Selenium::Driver.new(app,
                                   :browser => :remote,
                                   :url => SAUCE_CONNECT_URL,
                                   :desired_capabilities => Selenium::WebDriver::Remote::Capabilities.safari(caps))
  end

  Capybara.register_driver :rack_test do |app|
    Capybara::RackTest::Driver.new(app, follow_redirects: true, respect_data_method: true)
  end
end
