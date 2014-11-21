module MAPI
  module Services
    module MockMembers
      include MAPI::Services::Base

      def self.registered(app)
        service_root '/members', app
        swagger_api_root :members do
          api do
            key :path, '/{id}'
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

        relative_get '/:id' do
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
    end
  end
end