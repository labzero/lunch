module MAPI
  module Models
    class Customers
      include Swagger::Blocks
      swagger_model :CustomerDetails do
        key :required, [:phone, :title]
        property :phone do
          key :type, :string
          key :description, 'Customer Phone'
        end
        property :title do
          key :type, :string
          key :description, 'Customer Title'
        end
      end
    end
  end
end