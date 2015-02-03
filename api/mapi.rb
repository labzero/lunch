require 'sinatra/base'
require 'swagger/blocks'

require_relative 'shared/constants'

require_relative 'services/base'
require_relative 'services/mock_rates'
require_relative 'services/mock_members'
require_relative 'services/rates'
require_relative 'services/member_balance'
require_relative 'services/etransact_advances'

require_relative 'models/member'
require_relative 'models/member_balance_pledged_collateral'
require_relative 'models/member_balance_total_securities'
require_relative 'models/member_balance_effective_borrowing_capacity'
require_relative 'models/realtime_rate'
require_relative 'models/summary_rates'
require_relative 'models/etransact_advances'
require_relative 'models/member_capital_stock'
require_relative 'models/member_borrowing_capacity_details'
require_relative 'models/member_sta_activities'



module MAPI

  class Logger
    def initialize(app, logger)
      @app, @logger = app, logger
    end

    def call(env)
      env['rack.logger'] = @logger
      @app.call env
    end
  end

  class CommonLogger < Rack::CommonLogger
    def call(env)
      @logger = env['rack.logger']
      super
    end
  end

  class ServiceApp < Sinatra::Base
    require 'logging'
    require_relative '../lib/logging/appenders/rack'
    require 'sinatra/activerecord'
    register Sinatra::ActiveRecordExtension
    configure do
      set :show_exceptions, ENV['MAPI_SHOW_EXCEPTIONS'] == 'true'

      disable :logging # all logging does is add middleware. We will add similar middleware here
      logger = ::Logging.logger['MAPI']
      logger.add_appenders(Logging.appenders.file("#{settings.root}/../log/mapi-#{settings.environment}.log"))
      use MAPI::Logger, logger
      use MAPI::CommonLogger
      ::ActiveRecord::Base.logger = logger
    end

    error do
      error_handler env['sinatra.error']
    end

    def error_handler(error)
      logger.error error
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

    register MAPI::Services::MockRates
    register MAPI::Services::MockMembers
    register MAPI::Services::Rates
    register MAPI::Services::MemberBalance
    register MAPI::Services::EtransactAdvances
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
        key :path, '/mock_rates'
        key :description, 'Operations about dummy rates'
      end
      api do
        key :path, '/mock_members'
        key :description, 'Operations about dummy members'
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
