module MAPI
  module Models
    class MemberCurrentSecuritiesPosition
      include Swagger::Blocks
      swagger_model :MemberCurrentSecuritiesPosition do
        property :as_of_date do
          key :type, :date
          key :description, 'Last date FHLB calculated Current Securities Position for member'
        end
        property :total_original_par do
          key :type, :float
          key :description, 'The total original par for all current securities'
        end
        property :total_current_par do
          key :type, :float
          key :description, 'The total current par for all current securities'
        end
        property :total_market_value do
          key :type, :float
          key :description, 'The total market value for all current securities'
        end
        property :securities do
          key :type, :array
          key :description, 'An array of securities objects.'
          items do
            key :'$ref', :SecuritiessObject
          end
        end
      end
      swagger_model :SecuritiessObject do
        property :custody_account_number do
          key :type, :string
          key :description, 'Custody account number'
        end
        property :custody_account_type do
          key :type, :string
          key :description, 'Custody account type'
        end
        property :security_pledge_type do
          key :type, :string
          key :description, 'Security pledge type'
        end
        property :cusip do
          key :type, :string
          key :description, 'CUSIP Identifier'
        end
        property :description do
          key :type, :string
          key :description, "A desciption of the security"
        end
        property :reg_id do
          key :type, :string
          key :description, 'Reg ID'
        end
        property :pool_number do
          key :type, :string
          key :description, 'Pool Number'
        end
        property :coupon_rate do
          key :type, :float
          key :description, 'Original Par'
        end
        property :maturity_date do
          key :type, :date
          key :description, 'Maturity Date of security'
        end
        property :original_par do
          key :type, :float
          key :description, 'Original Par'
        end
        property :factor do
          key :type, :float
          key :description, 'Factor for security'
        end
        property :factor_date do
          key :type, :date
          key :description, 'Date of factor for security'
        end
        property :current_par do
          key :type, :float
          key :description, 'Current Par'
        end
        property :price do
          key :type, :float
          key :description, 'Price of the given security'
        end
        property :price_date do
          key :type, :date
          key :description, 'Date of the price of the given security'
        end
        property :market_value do
          key :type, :float
          key :description, 'Market value of the given security'
        end
      end
    end
  end
end