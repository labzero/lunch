module MAPI
  module Models
    class SummaryRates
      include Swagger::Blocks
      swagger_model :SummaryRates do
        property :loan_type do
          key :type, :LoanTypeObject
          key :description, 'An object containing LoanTermObjects relevant to the specified loan_type'
          key :enum, [:whole_loan, :agency, :aaa, :aa]
        end
      end
      swagger_model :LoanTypeObject do
        property :loan_term do
          key :type, :LoanTermObject
          key :description, 'An object containing all data relevant to the specified loan_term and loan_type'
          key :enum, [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']
        end
      end
      swagger_model :LoanTermObject do
        property :label do
          key :type, :string
          key :description, 'The label to use when displaying this loan term on a table'
        end
        property :payment_on do
          key :type, :string
          key :description, 'When the payment is due (typically "Maturity")'
        end
        property :interest_day_count do
          key :type, :string
          key :description, 'How interest is calculated (typically "Actual/Actual")'
        end
        property :maturity_date do
          key :type, :dateTime
          key :description, 'Date when payment is due'
        end
        property :rate do
          key :type, :string
          key :description, 'The rate of this loan_term and loan_type'
        end
        property :end_of_day do
          key :type, :boolean
          key :description, 'Has this particular product reached end-of-day?'
        end
      end
    end
  end
end
