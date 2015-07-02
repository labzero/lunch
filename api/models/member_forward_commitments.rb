module MAPI
  module Models
    class MemberForwardCommitments
      include Swagger::Blocks
      swagger_model :MemberForwardCommitments do
        property :as_of_date do
          key :type, :date
          key :description, 'Date for which the returned forward commitments are valid'
        end
        property :total_current_par do
          key :type, :float
          key :description, 'The total current par for all forward commitments'
        end
        property :advances do
          key :type, :array
          key :description, 'An array of advance objects.'
          items do
            key :'$ref', :AdvanceObject
          end
        end
      end
      swagger_model :AdvanceObject do
        property :trade_date do
          key :type, :date
          key :description, 'Date advance was made'
        end
        property :funding_date do
          key :type, :date
          key :description, 'Date advance will be funded'
        end
        property :maturity_date do
          key :type, :date
          key :description, 'Date advance matures'
        end
        property :advance_number do
          key :type, :string
          key :description, 'The number of the advance'
        end
        property :advance_type do
          key :type, :string
          key :description, 'The type of the advance'
        end
        property :current_par do
          key :type, :integer
          key :description, 'The current par of the advance'
        end
        property :interest_rate do
          key :type, :float
          key :description, 'The interest rate of the advance'
        end
      end
    end
  end
end