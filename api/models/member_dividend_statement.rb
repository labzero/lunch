module MAPI
  module Models
    class MemberDividendStatement
      include Swagger::Blocks
      swagger_model :MemberDividendStatement do
        property :transaction_date do
          key :type, :date
          key :description, 'Date of the dividend'
        end
        property :annualized_rate do
          key :type, :float
          key :description, 'Annualized dividend rate'
        end
        property :rate do
          key :type, :float
          key :description, 'Rate given in dollars per share'
        end
        property :average_shares_outstanding do
          key :type, :integer
          key :description, 'Total number of average shares outstanding'
        end
        property :shares_dividend do
          key :type, :float
          key :description, 'Capital Stock Dividend Class B Shares'
        end
        property :shares_par_value do
          key :type, :float
          key :description, 'Capital Stock Dividend Par Value'
        end
        property :cash_dividend do
          key :type, :float
          key :description, 'Dividend cash amount'
        end
        property :total_dividend do
          key :type, :float
          key :description, 'Total dividend amount'
        end
        property :sta_account_number do
          key :type, :string
          key :description, 'The STA account number for the member'
        end
        property :details do
          key :type, :array
          key :description, 'An array of dividend objects.'
          items do
            key :'$ref', :DividendObject
          end
        end
      end
      swagger_model :DividendObject do
        property :issue_date do
          key :type, :date
          key :description, 'Date dividend was issued'
        end
        property :certificate_sequence do
          key :type, :string
          key :description, 'The sequence for the dividend'
        end
        property :start_date do
          key :type, :date
          key :description, 'Start date of dividend'
        end
        property :end_date do
          key :type, :date
          key :description, 'End date of dividend'
        end
        property :shares_outstanding do
          key :type, :integer
          key :description, 'The number of shares outstanding'
        end
        property :days_outstanding do
          key :type, :integer
          key :description, 'The number of days the dividend has been outstanding'
        end
        property :average_shares_outstanding do
          key :type, :float
          key :description, 'The average number of shares outstanding'
        end
        property :dividend do
          key :type, :float
          key :description, 'Dividend value in dollars'
        end
      end
    end
  end
end