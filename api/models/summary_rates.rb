module MAPI
  module Models
    class SummaryRates
      include Swagger::Blocks
      swagger_model :SummaryRates do
        property :loan_term do
          key :type, :LoanTermObject
          key :description, 'An object containing all data relevant to the specified loan_term'
          key :enum, [:overnight, :open, :'1week', :'2week', :'3week', :'1month', :'2month', :'3month', :'6month', :'1year', :'2year', :'3year']
        end
      end
      swagger_model :LoanTermObject do
        property :whole_loan do
          key :type, :number
          key :format, :float
          key :description, 'The rate for this loan type'
        end
        property :agency do
          key :type, :number
          key :format, :float
          key :description, 'The rate for this loan type'
        end
        property :aaa do
          key :type, :number
          key :format, :float
          key :description, 'The rate for this loan type'
        end
        property :aa do
          key :type, :number
          key :format, :float
          key :description, 'The rate for this loan type'
        end
        property :payment_on do
          key :type, :string
          key :description, 'When the payment is due (typically "Maturity")'
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
      end
    end
  end
end