require 'sinatra/base'
require 'swagger/blocks'

class APIDocs < Sinatra::Base
  include Swagger::Blocks

  swagger_root do
    key :swaggerVersion, '1.2'
    key :apiVersion, '0.0.1'
    info do
      key :title, 'Swagger Example App'
    end
    api do
      key :path, '/rates'
      key :description, 'Operations about rates'
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

class APIMockRates < Sinatra::Base
  include Swagger::Blocks

  swagger_api_root :rates do
    key :swaggerVersion, '1.2'
    key :apiVersion, '0.0.1'
    key :basePath, "http://localhost:3100"
    key :resourcePath, '/rates'
    api do
      key :path, '/rates/{term}'
      operation do
        key :method, 'GET'
        key :summary, 'Find a rate by its term'
        key :notes, 'Returns an list of rates for that term'
        key :type, :Rate
        key :nickname, :getRatesByTerm
        parameter do
          key :paramType, :path
          key :name, :term
          key :required, true
          key :type, :string
          key :description, 'The term to find the rates for'
        end
        response_message do
          key :code, 400
          key :message, 'Invalid term supplied'
        end
      end
    end
  end

  get '/:term' do
    term = params[:term].to_i
    if term == 0
      halt 400, 'Invalid term supplied'
    end
    {
      rate: params[:term].to_i * 0.127
    }.to_json
  end
end

SWAGGER_CLASSES = [APIMockRates, APIDocs]
