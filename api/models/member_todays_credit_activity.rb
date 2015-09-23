module MAPI
  module Models
    class MemberTodaysCreditActivity
      include Swagger::Blocks
      swagger_model :MemberTodaysCreditActivity do
        property :credit_activities do
          key :type, :array
          key :description, 'An array of credit activity objects.'
          items do
            key :'$ref', :CreditActivityObject
          end
        end
      end
      swagger_model :CreditActivityObject do
        property :transaction_number do
          key :type, :string
          key :description, 'The transaction number for the activity'
        end
        property :current_par do
          key :type, :float
          key :description, 'The current par of the activity, in dollars'
        end
        property :interest_rate do
          key :type, :float
          key :description, 'The interest rate for the activity'
        end
        property :funding_date do
          key :type, :date
          key :description, 'The date the activity was funded'
        end
        property :maturity_date do
          key :type, :date
          key :description, 'The date the activity matures'
        end
        property :product_description do
          key :type, :string
          key :description, 'The product description for the activity - just concatenates the instrument_type, product and sub_product fields'
        end
        property :instrument_type do
          key :type, :string
          key :description, 'The instrument type of the activity'
        end
        property :status do
          key :type, :string
          key :description, 'The status of the activity'
        end
        property :termination_par do
          key :type, :float
          key :description, 'The par at termination for the activity'
        end
        property :termination_fee do
          key :type, :float
          key :description, 'The termination fee of the activity, in dollars'
        end
        property :termination_full_partial do
          key :type, :string
          key :description, 'A string signifying whether the repayment of the terminated activity was full or partial'
        end
        property :product do
          key :type, :string
          key :description, 'The product type of the activity'
        end
        property :sub_product do
          key :type, :string
          key :description, 'The sub-product type of the activity'
        end
      end
    end
  end
end
