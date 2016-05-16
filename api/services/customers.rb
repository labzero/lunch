require_relative 'customers/details'

module MAPI
  module Services
    module Customers

      include MAPI::Services::Base

      def self.registered(app)
        service_root '/customers', app
        swagger_api_root :customers do
          api do
            key :path, '/{email}/'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve customer details'
              key :notes, 'Returns basic details about a customer'
              key :type, :CustomerDetails
              key :nickname, :getCustomerDetails
              parameter do
                key :paramType, :path
                key :name, :email
                key :required, true
                key :type, :string
                key :description, 'The email to find customer by'
              end
            end
          end
        end

        relative_get '/:email/' do
          email = params[:email]
          customer_details = MAPI::Services::Customers::Details.customer_details(self, logger, email)
          if customer_details.nil?
            logger.error 'Customer not found'
            halt 404
          end
          customer_details.to_json
        end
      end
    end
  end
end