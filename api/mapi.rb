require 'sinatra/base'
require 'swagger/blocks'
require 'active_support/concern'
require 'active_support/time'
require 'active_job'
require 'savon'
HTTPI::Adapter.use # force Savon to load its adapters

require_relative '../lib/redis_helper'
ActiveJob::Base.queue_adapter = :resque
ENV['RESQUE_CONFIG_FILE'] ||= File.join(__dir__, '..', 'config', 'resque.yml')
require_relative '../config/initializers/resque'

require_relative 'services/base'
['shared', 'mailers', 'services', 'models', 'jobs'].each do |dir|
  Dir::glob(File.join(__dir__, dir, '**', '*.rb')) do |file|
    require file
  end
end

require 'newrelic_rpm'
NewRelic::Agent.add_instrumentation(File.join(__dir__, '..', 'lib', 'new_relic', 'instrumentation', '**', '*.rb')) if defined?(NewRelic::Agent)

ENV['TZ'] ||= ENV['TIMEZONE'] || 'America/Los_Angeles'
Time.zone = ENV['TIMEZONE'] || 'America/Los_Angeles'
Time.zone_default = Time.zone

module MAPI

  class Logger
    def initialize(app, logger)
      @app, @logger = app, logger
    end

    def call(env)
      resp = nil
      request_id = env['HTTP_X_REQUEST_ID'] || SecureRandom.uuid
      user_id = env['HTTP_X_USER_ID']
      tags = ["request_id=#{request_id}", "user_id=#{user_id}"]
      @logger.tagged(*tags) do
        env['rack.logger'] = @logger
        env['logger.tags'] = tags
        env['mapi.request.id'] = request_id
        env['mapi.request.user_id'] = user_id
        resp = @app.call env
      end
      resp
    ensure
      ActiveSupport::LogSubscriber.flush_all!
    end
  end

  class CommonLogger < Rack::CommonLogger
    def call(env)
      @logger = env['rack.logger']
      began_at = Time.now
      status, header, body = @app.call(env)
      header = Rack::Utils::HeaderHash.new(header)
      body = Rack::BodyProxy.new(body) { @logger.tagged(env['logger.tags']) { log(env, status, header, began_at) } }
      [status, header, body]
    end
  end

  class ServiceApp < Sinatra::Base
    require 'logging'
    require 'sinatra/activerecord'
    register Sinatra::ActiveRecordExtension
    configure do
      set :show_exceptions, ENV['MAPI_SHOW_EXCEPTIONS'] == 'true'

      disable :logging # all logging does is add middleware. We will add similar middleware here
      logger = ActiveSupport::TaggedLogging.new(::Logger.new("#{settings.root}/../log/mapi-#{settings.environment}.log", 'daily'))
      logger.level = ::Logger::Severity.const_get((ENV['LOG_LEVEL'] || :info).to_s.upcase)
      class << logger
        def <<(msg)
          info(msg.chomp)
        end
      end
      use MAPI::Logger, logger
      use MAPI::CommonLogger
      ::ActiveRecord::Base.logger = logger
      ::ActiveRecord::Base.default_timezone = :local
    end

    error do
      error_handler env['sinatra.error']
    end

    def request_id
      env['mapi.request.id']
    end

    def request_user_id
      env['mapi.request.user_id']
    end

    def error_handler(error)
      logger.error error
      if ENV['RACK_ENV'] != 'production'
        logger.error error.backtrace.join("\n")
      end
      'Unexpected Server Error'
    end

    def self.authentication_block
      Proc.new do |token, options, env|
        if token != ENV['MAPI_SECRET_TOKEN']
          req = Rack::Request.new(env)
          is_valid = req.params['api_key'] == ENV['MAPI_SECRET_TOKEN']
          env['QUERY_STRING'].gsub! /(^|&)api_key=([^&]*)(&|$)/, '\1api_key=[SANITIZED]\3' # mask the API token after checking it
          is_valid
        else
          true
        end
      end
    end

    require 'rack/token_auth'
    use Rack::TokenAuth, &authentication_block

    ActiveRecord::Base.establish_connection(:cdb) if environment == :production

    get '/' do
      settings.environment.to_s
    end

    get '/raise_error' do
      raise 'Some Error'
    end

    register MAPI::Services::Rates
    register MAPI::Services::Member
    register MAPI::Services::EtransactAdvances
    register MAPI::Services::Users
    register MAPI::Services::Health
    register MAPI::Services::Fees
    register MAPI::Services::Customers
    register MAPI::Services::Calendar
  end

  class DocApp < Sinatra::Base
    include Swagger::Blocks

    swagger_root do
      key :swaggerVersion, MAPI.swagger_version
      key :apiVersion, MAPI.api_version
      info do
        key :title, 'FHLBSF Member Site Swagger App'
      end
      authorization :apiKey do
        key :type, 'apiKey'
        key :name, 'Authorization'
        key :in, 'header'
      end
      api do
        key :path, '/rates'
        key :description, 'Operations about rates'
      end
      api do
        key :path, '/member'
        key :description, 'Operations about members'
      end
      api do
        key :path, '/etransact_advances'
        key :description, 'Operations about etransact advances'
      end
      api do
        key :path, '/users'
        key :description, 'Operations about users'
      end
      api do
        key :path, '/healthy'
        key :description, 'Health status'
      end
      api do
        key :path, '/fees'
        key :description, 'Operations about fees associated with FHLB services and procedures'
      end
      api do
        key :path, '/customers'
        key :description, 'Operations about customers'
      end
      api do
        key :path, '/calendar'
        key :description, 'Operations pertaining to the FHLB business calendar'
      end
    end

    get '/' do
      redirect '/index.html'
    end

    get '/apidocs' do
      json = Swagger::Blocks.build_root_json(SWAGGER_CLASSES)
      json.to_json
    end

    get '/apidocs/:id' do
      json = Swagger::Blocks.build_api_json(params[:id], SWAGGER_CLASSES)
      json.to_json
    end
  end

  class HealthApp < Sinatra::Base
    get '/' do
      'OK'
    end
  end
end

SWAGGER_CLASSES =  [MAPI::Services.constants.collect{|c| const = MAPI::Services.const_get(c); const if const.is_a?(Module)}, MAPI::Models.constants.collect{|c| const = MAPI::Models.const_get(c); const if const.is_a?(Class)}, MAPI::DocApp].reject(&:nil?).flatten
