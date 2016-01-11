module MAPI
  module Models
    class MemberQuickAdvanceRequest
      include Swagger::Blocks
      swagger_model :MemberQuickAdvanceRequest do
        key :required, [:amount, :advance_type, :advance_term, :rate, :signer, :maturity_date]
        property :amount do
          key :type, :Numeric
          key :description, 'Amount to execute.'
        end
        property :advance_type do
          key :type, :string
          key :description, 'Collateral type.'
        end
        property :advance_term do
          key :type, :string
          key :description, 'Term of the advance.'
        end
        property :rate do
          key :type, :Numeric
          key :description, 'Advance rate.'
        end
        property :signer do
          key :type, :string
          key :description, 'Authorized signer.'
        end
        property :maturity_date do
          key :type, :string
          key :description, 'Maturity date.'
        end
      end
    end
  end
end