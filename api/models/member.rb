module MAPI
  module Models
    class Member
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
  end
end