require 'sinatra/base'
require 'swagger/blocks'
require 'faker'

class APIDocs < Sinatra::Base
  include Swagger::Blocks

  swagger_root do
    key :swaggerVersion, '1.2'
    key :apiVersion, '0.0.1'
    info do
      key :title, 'FHLBSF Member Site Swagger App'
    end
    api do
      key :path, '/rates'
      key :description, 'Operations about rates'
    end
    api do
      key :path, '/members'
      key :description, 'Operations about members'
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
      rate: params[:term].to_i * 0.124
    }.to_json
  end
end

class APIMockMembers < Sinatra::Base
  include Swagger::Blocks

  swagger_api_root :members do
    key :swaggerVersion, '1.2'
    key :apiVersion, '0.0.1'
    key :basePath, "http://localhost:3100"
    key :resourcePath, '/members'
    api do
      key :path, '/members/{id}'
      operation do
        key :method, 'GET'
        key :summary, 'Find a member by id'
        key :notes, 'Returns member info'
        key :type, :Member
        key :nickname, :getMemberById
        parameter do
          key :paramType, :path
          key :name, :id
          key :required, true
          key :type, :string
          key :description, 'The id to find the members from'
        end
        response_message do
          key :code, 400
          key :message, 'Invalid term supplied'
        end
      end
    end
  end

  get '/:id' do
    {
        member:
            {
                id: params[:id],
                name: Faker::Company.name,
                address: Faker::Address.street_address
            }
    }.to_json
  end
end

class ModelsContainer
  include Swagger::Blocks
  swagger_model :Member do
    key :id, :Member
    key :required, [:id, :name]
    property :id do
      key :type, :integer
      key :format, :int64
      key :description, 'member id'
      key :minimum, '0.0'
      key :maximum, '100000.0'
    end
    property :name do
      key :type, :string
    end
    property :address do
      key :type, :string
    end
  end
end

SWAGGER_CLASSES = [APIMockRates, APIMockMembers, APIDocs, ModelsContainer]
