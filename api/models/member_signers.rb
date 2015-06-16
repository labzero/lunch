module MAPI
  module Models
    class MemberSigners
      include Swagger::Blocks
      swagger_model :MemberSigners do
        property :name do
          key :type, :string
          key :description, 'The full name of the signer (e.g. `Thomas Jefferson`)'
        end
        property :username do
          key :type, :string
          key :description, 'The username of the signer (e.g. `tjefferson`)'
        end
        property :roles do
          key :type, :array
          key :description, 'An array of roles.'
          items do
            key :type, :string
            key :description, 'Role (e.g. `signer-wiretransfers`)'
          end
        end
      end
    end
  end
end