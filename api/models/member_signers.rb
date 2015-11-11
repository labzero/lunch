module MAPI
  module Models
    class MemberSigners
      include Swagger::Blocks
      swagger_model :MemberSigners do
        key :required, [:name, :username, :roles, :last_name, :first_name]
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
        property :last_name do
          key :type, :string
          key :description, 'The last name of the signer (e.g `Jefferson`)'
        end
        property :first_name do
          key :type, :string
          key :description, 'The first name of the signer (e.g `Thomas`)'
        end
      end
    end
  end
end