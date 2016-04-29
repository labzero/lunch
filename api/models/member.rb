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
          key :minimum, '0'
        end
        property :name do
          key :type, :string
        end
        property :address do
          key :type, :string
        end
      end
      swagger_model :MemberDetails do
        key :required, [:name, :fhfa_number, :sta_number, :dual_signers_required, :street, :city, :state, :postal_code]
        property :name do
          key :type, :string
          key :description, 'The name of the member.'
        end
        property :fhfa_number do
          key :type, :string
          key :description, 'The Federal Housing Finance Agency number of the member.'
        end
        property :sta_number do
          key :type, :string
          key :description, 'The Settlment/Transaction Account number of the member.'
        end
        property :dual_signers_required do
          key :type, :boolean
          key :description, 'Indicates whether this member requires multiple signers to take out advances.'
        end
        property :street do
          key :type, :string
          key :description, 'Member Address.'
        end
        property :city do
          key :type, :string
          key :description, 'Member City.'
        end
        property :state do
          key :type, :string
          key :description, 'Member State.'
        end
        property :postal_code do
          key :type, :string
          key :description, 'Member Postal Code.'
        end
      end
    end
  end
end