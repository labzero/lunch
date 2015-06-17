module MAPI
  module Models
    class ExecuteAdvance
      include Swagger::Blocks
      swagger_model :ExecuteAdvance do
        property :status do
          key :type, :string
          key :description, 'Result of execute trade'
        end
        property :confirmation_number do
          key :type, :string
          key :description, 'Advances number'
        end
        property :advance_rate do
          key :type, :Numeric
          key :description, 'Advances interest rate'
        end
        property :advance_amount do
          key :type, :Numeric
          key :description, 'Advances current par'
        end
        property :advance_term do
          key :type, :string
          key :description, 'Term of the Advance'
        end
        property :advance_type do
          key :type, :string
          key :description, 'Description of the Advances type'
        end
        property :interest_day_count do
          key :type, :string
          key :description, 'Interest Day Count'
        end
        property :payment_on do
          key :type, :string
          key :description, 'Payment On Type'
        end
        property :funding_date do
          key :type, :date
          key :description, 'Advances Funding/Settlement Date'
        end
        property :maturity_date do
          key :type, :string
          key :description, 'Advances Maturity Date or Open in cases for OPEN VRC advances'
        end
      end
    end
  end
end