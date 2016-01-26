module MAPI
  module Models
    class MemberSecuritiesPosition
      include Swagger::Blocks
      swagger_model :MemberSecuritiesPosition do
        key :required, [:as_of_date, :total_original_par, :total_current_par, :total_market_value, :securities]
        property :as_of_date do
          key :type, :string
          key :format, :date
          key :description, 'Date FHLB calculated Securities Position'
        end
        property :total_original_par do
          key :type, :number
          key :format, :float
          key :description, 'The total original par for given securities'
        end
        property :total_current_par do
          key :type, :number
          key :format, :float
          key :description, 'The total current par for given securities'
        end
        property :total_market_value do
          key :type, :number
          key :format, :float
          key :description, 'The total market value for given securities'
        end
        property :securities do
          key :type, :array
          key :description, 'An array of securities objects.'
          items do
            key :'$ref', :SecuritiesObject
          end
        end
      end
      swagger_model :SecuritiesObject do
        key :required, [:custody_account_number, :custody_account_type, :security_pledge_type, :cusip, :description, :reg_id, :pool_number, :coupon_rate, :maturity_date, :original_par, :factor, :factor_date, :current_par, :price, :price_date, :market_value]
        property :custody_account_number do
          key :type, :string
          key :description, 'Custody account number'
        end
        property :custody_account_type do
          key :type, :string
          key :description, 'Custody account type'
          key :enum, ['P','U']
        end
        property :security_pledge_type do
          key :type, :string
          key :description, 'Security pledge type'
          key :enum, ['Standard', 'SBC', 'SAFE']
        end
        property :cusip do
          key :type, :string
          key :description, 'CUSIP Identifier'
        end
        property :description do
          key :type, :string
          key :description, "A description of the security"
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
          key :type, :number
          key :format, :float
          key :description, 'Original Par'
        end
        property :maturity_date do
          key :type, :string
          key :format, :date
          key :description, 'Maturity Date of security'
        end
        property :original_par do
          key :type, :number
          key :format, :float
          key :description, 'Original Par'
        end
        property :factor do
          key :type, :number
          key :format, :float
          key :description, 'Factor for security'
        end
        property :factor_date do
          key :type, :string
          key :format, :date
          key :description, 'Date of factor for security'
        end
        property :current_par do
          key :type, :number
          key :format, :float
          key :description, 'Current Par'
        end
        property :price do
          key :type, :number
          key :format, :float
          key :description, 'Price of the given security'
        end
        property :price_date do
          key :type, :string
          key :format, :date
          key :description, 'Date of the price of the given security'
        end
        property :market_value do
          key :type, :number
          key :format, :float
          key :description, 'Market value of the given security'
        end
        property :eligibility do
          key :type, :string
          key :description, 'The eligibility of the security (yes, no or unknown)'
          key :notes, 'This value only returned for the `managed_securities` endpoint'
        end
        property :authorized_by do
          key :type, :string
          key :description, 'The name of the person who authorized the security'
          key :notes, 'This value only returned for the `managed_securities` endpoint'
        end
        property :borrowing_capacity do
          key :type, :number
          key :format, :float
          key :description, 'The borrowing capacity assigned to the given security at the present time, based on its market value and classification'
          key :notes, 'This value only returned for the `managed_securities` endpoint'
        end
      end
    end
  end
end