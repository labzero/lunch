module MAPI
  module Services
    module MockRates
      include MAPI::Services::Base

      def self.registered(app)
        service_root '/rates', app
        swagger_api_root :rates do
          api do
            key :path, "/{term}"
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

        relative_get "/:term" do
          term = params[:term].to_i
          if term == 0
            halt 400, 'Invalid term supplied'
          end
          {
            rate: params[:term].to_i * 0.124
          }.to_json
        end
      end
    end
  end
end