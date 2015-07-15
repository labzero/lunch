module MAPI
  module Models
    class CurrentSTARate
      include Swagger::Blocks
      swagger_model :CurrentSTARate do
        property :account_number do
          key :type, :string
          key :description, 'The account number for the given STA'
        end
        property :date do
          key :type, :date
          key :description, 'The date on which the rate was calculated'
        end
        property :rate do
          key :type, :float
          key :description, 'The current STA rate for the given member'
        end
      end
    end
  end
end
