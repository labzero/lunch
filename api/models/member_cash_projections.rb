module MAPI
  module Models
    class MemberCashProjections
      include Swagger::Blocks
      swagger_model :MemberCashProjections do
        property :as_of_date do
          key :type, :date
          key :description, 'Last date FHLB calculated Cash Projections for members'
        end
        property :total_net_amount do
          key :type, :float
          key :description, 'The total net amount for all cash projections'
        end
        property :total_principal do
          key :type, :float
          key :description, 'The total principal for all cash projections'
        end
        property :total_interest do
          key :type, :float
          key :description, 'The total interest for all cash projections'
        end
        property :projections do
          key :type, :array
          key :description, 'An array of projections objects.'
          items do
            key :'$ref', :ProjectionsObject
          end
        end
      end
      swagger_model :ProjectionsObject do
        property :settlement_date do
          key :type, :date
          key :description, 'Settlement Date'
        end
        property :custody_account do
          key :type, :string
          key :description, 'Custody Account'
        end
        property :cusip do
          key :type, :string
          key :description, 'CUSIP Identifier'
        end
        property :description do
          key :type, :string
          key :description, "A desciption of the cash projection's security"
        end
        property :transaction_code do
          key :type, :string
          key :description, 'Transaction Code'
        end
        property :pool_number do
          key :type, :string
          key :description, 'Pool Number'
        end
        property :original_par do
          key :type, :float
          key :description, 'Original Par'
        end
        property :coupon_rate do
          key :type, :float
          key :description, 'Original Par'
        end
        property :maturity_date do
          key :type, :date
          key :description, 'Maturity Date of security'
        end
        property :principal do
          key :type, :float
          key :description, 'The projected principal for the security'
        end
        property :interest do
          key :type, :float
          key :description, 'The projected interest for the security'
        end
        property :total do
          key :type, :float
          key :description, 'The projected total for the security'
        end
      end
    end
  end
end