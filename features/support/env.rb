require 'dotenv'
Dotenv.load

require 'capybara/rspec'
require 'capybara/cucumber'
require 'cucumber/rspec/doubles'

require_relative 'custom_config'
include CustomConfig

require 'i18n'
I18n.load_path += Dir.glob('config/locales/*.yml')

require 'active_support/all'
Time.zone = ENV['TIMEZONE'] || 'America/Los_Angeles'

require_relative 'utils'

custom_host = ENV['APP_HOST'] || env_config['app_host']

failed_scenarios = []
passed_scenarios = []
sauce_job_id = nil
run_start_time = nil
first_step_time_delta = nil

def human_location(scenario)
  scenario.location[:file] + ':' + scenario.location[:lines].to_s
end

if is_parallel_secondary && !custom_host
  timeout_at = Time.now + 120.seconds
  while !File.exists?('cucumber-primary-ready')
    if Time.now > timeout_at
      raise "Cucumber runner #{parallel_test_number} timed out waiting for the primary runner to start!"
    end
    sleep(1)
  end
end

if !custom_host
  ENV['FHLB_INTERNAL_IPS'] = '0.0.0.0/0 0::0/0' # all IPs are internal
  ENV['RAILS_ENV'] ||= 'test' # for some reason we default to development in some cases
  ENV['RACK_ENV'] ||= 'test'
  ENV['REDIS_URL'] ||= 'redis://localhost:6379/'

  require_relative '../../lib/redis_helper'
  resque_namespace = ['resque', ENV['RAILS_ENV'], 'cucumber', parallel_test_number, Process.pid].compact.join('-')
  ENV['RESQUE_REDIS_URL'] ||= RedisHelper.add_url_namespace(ENV['REDIS_URL'], resque_namespace)
  flipper_namespace = ['flipper', ENV['RAILS_ENV'], 'cucumber', parallel_test_number, Process.pid].compact.join('-')
  ENV['FLIPPER_REDIS_URL'] ||= RedisHelper.add_url_namespace(ENV['REDIS_URL'], flipper_namespace)
  cache_namespace = ['cache', ENV['RAILS_ENV'], 'cucumber', parallel_test_number, Process.pid].compact.join('-')
  ENV['CACHE_REDIS_URL'] ||= RedisHelper.add_url_namespace(ENV['REDIS_URL'], cache_namespace)

  log "Flipper initialized (#{ENV['FLIPPER_REDIS_URL']})"

  require 'open3'
  require ::File.expand_path('../../../config/environment',  __FILE__)
  require 'capybara/rails'
  require 'net/ping/tcp'

  WebMock.allow_net_connect! # allow all Net connections

  AfterConfiguration do
    DatabaseCleaner.clean_with :truncation if !is_parallel || is_parallel_primary
  end

  ldap_output = nil
  port_retry do |ldap_port|
    ldap_root = Rails.root.join('tmp', "openldap-data-#{Process.pid}")
    ldap_server = File.expand_path('../../../ldap/run-server',  __FILE__) + " --port #{ldap_port} --root-dir #{ldap_root} --verbose"
    log "LDAP starting, ldap://localhost:#{ldap_port}"

    ldap_output = ENV['VERBOSE'] ? STDOUT : StringIO.new
    service = SupportingService.new('LDAP', ldap_server, forward_output: ldap_output).run
    service.after_kill = Proc.new { FileUtils.rm_rf(ldap_root) }

    begin
      check_service(service, ldap_port)
    rescue SupportingService::ServiceLaunchError => e
      unless ldap_output == STDOUT
        ldap_output.rewind
        IO.copy_stream(ldap_output, STDOUT)
        ldap_output.close
      end
      raise e
    end

    log 'LDAP started.'
    log 'LDAP seeding'
    seed_output = `#{ldap_server} --reseed 2>&1`
    seed_success = $?.success?
    if ENV['VERBOSE'] || !seed_success
      seed_output.split("\n").each do |line|
        log line
      end
    end
    unless seed_success
      log 'LDAP seed failed.'
      raise SupportingService::ServiceLaunchError.new('LDAP seed failed')
    end
    log 'LDAP seeded.'
    ENV['LDAP_PORT'] = ldap_port.to_s
    ENV['LDAP_EXTRANET_PORT'] = ldap_port.to_s
    ldap_output.close unless ldap_output == STDOUT
  end


  port_retry do |mapi_port|
    log "MAPI starting: http://localhost:#{mapi_port}"
    mapi_server = "rackup --port #{mapi_port} #{File.expand_path('../../../api/config.ru', __FILE__)}"
    service = SupportingService.new('MAPI', mapi_server, env: {'RACK_ENV' => 'test'}, forward_output: ENV['VERBOSE']).run
    check_service(service, mapi_port)

    log 'MAPI Started.'
    ENV['MAPI_ENDPOINT'] = "http://localhost:#{mapi_port}/mapi"
  end

  verbose = ENV['VERBOSE'] # Need to remove the VERBOSE env variable due to a conflict with Resque::VerboseFormatter and ActiveJob logging
  begin
    ENV.delete('VERBOSE')
    log "resque-pool starting (#{ENV['RESQUE_REDIS_URL']})"
    resque_pool = "resque-pool --single-process-group -E #{ENV['RAILS_ENV'] || ENV['RACK_ENV']}"
    resque_output = verbose ? STDOUT : StringIO.new
    resque_service = SupportingService.new('Resque', resque_pool, env: {'TERM_CHILD' => '1'}, forward_output: resque_output, kill_signal: 'TERM').run
  ensure
    ENV['VERBOSE'] = verbose # reset the VERBOSE env variable after resque process is finished.
  end

  resque_time_out_at = Time.now + 20.seconds

  while Time.now < resque_time_out_at && Resque.workers.count == 0
    Resque.workers.each do |worker|
      worker.prune_dead_workers # helps ensure we have an accurate count
    end
    sleep 1
  end

  unless Resque.workers.count > 0
    resque_service.kill
    unless resque_output == STDOUT
      resque_output.rewind
      IO.copy_stream(resque_output, STDOUT)
      resque_output.close
    end
    raise 'resque-pool failed to start'
  else
    resque_output.close unless resque_output == STDOUT
  end

  log 'resque-pool started.'

  # ensure we have at least one feature
  feature_name = SecureRandom.hex
  at_exit do
    Rails.application.flipper[feature_name].try(:remove)
  end
  Rails.application.flipper[feature_name].disable
else
  Capybara.app_host = custom_host
end

log "Capybara.app_host: #{Capybara.app_host}"

at_exit do
  log "App Health Check Results: "
  STDOUT.flush
  log %x[curl -m 10 -sL #{Capybara.app_host}/healthy]
  log "Finished run `#{run_name}`"
end

AfterConfiguration do
  if Capybara.app_host.nil?
    Capybara.app_host = "#{Capybara.app_host || ('http://' + Capybara.current_session.server.host)}:#{Capybara.server_port || (Capybara.current_session.server ? Capybara.current_session.server.port : false) || 80}"
  end
  Rails.configuration.mapi.endpoint = ENV['MAPI_ENDPOINT'] unless custom_host
  url = Capybara.app_host
  log(url)
  result = nil
  10.times do |i|
    result = %x[curl -w "%{http_code}" -m 3 -sL #{url} -o /dev/null]
    if result == '200'
      break
    end
    wait_time = ENV['WAIT_TIME'] ? ENV['WAIT_TIME'].to_i : 3
    log "App not serving heartbeat (#{url}, #{result})... waiting #{wait_time}s (#{i + 1} tr"+(i==0 ? "y" : "ies")+")"
    STDOUT.flush
    sleep wait_time
  end
  unless result == '200'
    error = %x[curl -m 3 -sL #{url}]
    log(error)
    raise Capybara::CapybaraError.new('Server failed to serve heartbeat')
  end
  sleep 10 #sleep 10 more seconds after we get our first 200 response to let the app come up more
  if !is_parallel || is_parallel_primary
    require Rails.root.join('db', 'seeds.rb') unless custom_host
  end

  if is_parallel_primary
    FileUtils.touch('cucumber-primary-ready')
    at_exit do
      FileUtils.rm_rf('cucumber-primary-ready')
    end
    sleep(30) # primary runner needs to sleep to make sure secondary workers see the sentinel (in the case where the primary work exits quickly... ie no work to do)
  end

  sleep(parallel_test_number.to_i * 3) # stagger runners to avoid certain race conditions

  log "Starting run `#{run_name}`"
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

Around do |scenario, block|
  begin
    block.call
  ensure
    Timecop.return if defined?(Timecop)
  end
end

Around('@local-only') do |scenario, block|
  if custom_host
    skip_this_scenario
  else
    block.call
  end
end

Around do |scenario, block|
  features = {}
  feature_state = {}
  scenario.source_tag_names.each do |tag|
    matches = tag.match(/\A@flip-(on|off)-(.+)\z/)
    if matches
      features[matches[2]] = (matches[1] == 'on')
    end
  end
  unless custom_host
    features.each do |feature_name, enable|
      feature = Rails.application.flipper[feature_name]
      feature_state[feature] = {
          groups: feature.groups_value,
          boolean: feature.boolean_value,
          actors: feature.actors_value,
          percentage_of_actors: feature.percentage_of_actors_value,
          percentage_of_time: feature.percentage_of_time_value
        }
    end
    features.each do |feature_name, enable|
      feature = Rails.application.flipper[feature_name]
      enable ? feature.enable : feature.disable
    end
  end
  begin
    if custom_host && features.present? # we can't mutate custom hosts, so skip the scenario
      skip_this_scenario
    else
      block.call
    end
  ensure
    feature_state.each do |feature, state|
      state[:boolean] ? feature.enable : feature.disable
      feature.enable_percentage_of_time(state[:percentage_of_time])
      feature.enable_percentage_of_actors(state[:percentage_of_actors])
      state[:groups].each do |group|
        feature.enable_group(group)
      end
      state[:actors].each do |actor|
        feature.enable_group(actor)
      end
    end
  end
end
