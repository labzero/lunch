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


module MAPI

  class ServiceApp < Sinatra::Base
    set :show_exceptions, ENV['MAPI_SHOW_EXCEPTIONS'] == 'true'
    require 'sinatra/activerecord'
    register Sinatra::ActiveRecordExtension

    require 'rack/token_auth'
    use Rack::TokenAuth do |token, options, env|
      if token != ENV['MAPI_SECRET_TOKEN']
        req = Rack::Request.new(env)
        req.params['api_key'] == ENV['MAPI_SECRET_TOKEN']
      else
        true
      end
    end

    ActiveRecord::Base.establish_connection(:cdb) if environment == :production

    get '/' do
      settings.environment.to_s
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
