module MAPI
  module Models
    class MemberContacts
      include Swagger::Blocks
      swagger_model :MemberContacts do
        key :required, [:cam, :rm]
        property :cam do
          key :type, :ContactObject
          key :description, 'An object containing contact info for the member\'s Collateral Asset Manager'
        end
        property :rm do
          key :type, :ContactObject
          key :description, 'An object containing contact info for the member\'s Relationship Manager'
        end
      end
      swagger_model :ContactObject do
        key :required, [:username, :full_name, :email]
        property :username do
          key :type, :string
          key :description, 'The FHLB username of the contact.'
        end
        property :full_name do
          key :type, :string
          key :description, 'The full name of the contact.'
        end
        property :email do
          key :type, :string
          key :description, 'The email address of the contact.'
        end
        property :phone_number do
          key :type, :string
          key :description, 'The phone number of the contact.'
        end
        property :first_name do
          key :type, :string
          key :description, 'The first name of the contact.'
        end
        property :last_name do
          key :type, :string
          key :description, 'The last name of the contact.'
        end
      end
    end
  end
end