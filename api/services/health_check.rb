module MAPI
  module Services
    module HealthCheck
      include MAPI::Services::Base
      def self.registered(app)
        service_root '/healthy', app
        swagger_api_root :healthy do
          api do
            key :path, ''
            operation do
              key :method, 'GET'
              key :summary, 'Check if the node is healthy'
              key :notes, 'Returns 200 OK if the node is healthy.'
              key :nickname, :healthCheck
              response_message do
                key :code, 200
                key :message, 'The node is healthy.'
              end
              response_message do
                key :code, 503
                key :message, 'The node is unhealthy.'
              end
            end
          end
        end
        relative_get '' do
          'OK'
        end
      end
    end
  end
end
