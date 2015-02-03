module MAPI
  module Models
    class AdvancesDetails
      include Swagger::Blocks
      swagger_model :AdvancesDetails do
        property :as_of_date do
          key :type, :date
          key :description, 'Advances details as of date'
        end
        property :structured_product_indication_date do
          key :type, :date
          key :description, 'Structured product Prepayment valuation Date'
        end
        property :advances_details do
          key :type, :AdvancesDetailsObject
          key :description, 'An object containing the Advances Details information'
        end
      end
      swagger_model :AdvancesDetailsObject do
        property :trade_date do
          key :type, :date
          key :description, 'Advances Trade Date'
        end
        property :funding_date do
          key :type, :date
          key :description, 'Advances Funding/Settlement Date'
        end
        property :maturity_date do
          key :type, :date
          key :description, 'Advances Maturity Date or null in cases for OPEN VRC advances'
        end
        property :current_par do
          key :type, :Numeric
          key :description, 'Advances current par'
        end
        property :interest_rate do
          key :type, :Numeric
          key :description, 'Advances interest rate.  It could be up to 5 decimal points.'
        end
        property :next_interest_pay_date do
          key :type, :date
          key :description, 'Date for the next interest payment'
        end
        property :accrued_interest do
          key :type, :Numeric
          key :description, 'Accrued interest'
        end
        property :estimated_next_interest_payment do
          key :type, :Numeric
          key :description, 'Estimated amount of the next interest payment. May be null'
        end
        property :interest_payment_frequency do
          key :type, :string
          key :description, 'Interest payment frequency'
        end
        property :day_count_basis do
          key :type, :string
          key :description, 'Day count basis'
        end
        property :advance_types do
          key :type, :string
          key :description, 'Description of the Advances type'
        end
        property :advance_number do
          key :type, :string
          key :description, 'Advances number'
        end
        property :discount_program do
          key :type, :string
          key :description, 'Discount program that is applied to the Advances. May be null'
        end
        property :prepayment_fee_indication do
          key :type, :Numeric
          key :description, 'Prepayment fees indication amount.  May be null due to not applicable or not available or historical image'
        end
        property :notes do
          key :type, :string
          key :description, 'Notes indicator that is applicable to Prepayment fees indication amount stating why it is not avaialble. Null for historical image'
        end
        property :structure_product_prepay_valuation_date do
          key :type, :string
          key :description, 'Date when structure advances prepayment indication amount was calculated.  Null when advances are not structured type or when no prepayment indication amount was calculated'
        end
      end
    end
  end
end
