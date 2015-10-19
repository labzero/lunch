module MAPI
  module Models
    class ActiveAdvances
      include Swagger::Blocks
      swagger_model :ActiveAdvances do
        property :trade_date do
          key :type, :date
          key :description, 'Advances Trade Date'
        end
        property :funding_date do
          key :type, :date
          key :description, 'Advances Funding/Settlement Date'
        end
        property :maturity_date do
          key :type, :string
          key :description, 'Advances Maturity Date or Open in cases for OPEN VRC advances'
        end
        property :advance_number do
          key :type, :string
          key :description, 'Advances number'
        end
        property :advance_type do
          key :type, :string
          key :description, 'Description of the Advances type'
        end
        property :status do
          key :type, :string
          key :description, 'Processing or Outstanding'
        end
        property :interest_rate do
          key :type, :Numeric
          key :description, 'Advances interest rate.  It could be up to 5 decimal points.'
        end
        property :current_par do
          key :type, :Numeric
          key :description, 'Advances current par'
        end
      end
    end
  end
end
