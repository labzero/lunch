module MAPI
  module Models
    class MemberParallelShift
      include Swagger::Blocks
      swagger_model :MemberParallelShift do
        property :as_of_date do
          key :type, :date
          key :description, 'Date for which the returned advances are valid'
        end
        property :advances do
          key :type, :array
          key :description, 'An array of advance objects.'
          items do
            key :'$ref', :PutableAdvanceObject
          end
        end
      end
      swagger_model :PutableAdvanceObject do
        property :advance_number do
          key :type, :string
          key :description, 'The number of the advance'
        end
        property :issue_date do
          key :type, :date
          key :description, 'Date advance was issued'
        end
        property :interest_rate do
          key :type, :float
          key :description, 'The interest rate of the advance'
        end
        property :shift_neg_300 do
          key :type, :float
          key :description, 'Valuation estimate of advance with parallel-interest rate movement of minus 300 basis points'
        end
        property :shift_neg_200 do
          key :type, :float
          key :description, 'Valuation estimate of advance with parallel-interest rate movement of minus 200 basis points'
        end
        property :shift_neg_100 do
          key :type, :float
          key :description, 'Valuation estimate of advance with parallel-interest rate movement of minus 100 basis points'
        end
        property :shift_0 do
          key :type, :float
          key :description, 'Valuation estimate of advance with no parallel-interest rate movement'
        end
        property :shift_100 do
          key :type, :float
          key :description, 'Valuation estimate of advance with parallel-interest rate movement of plus 100 basis points'
        end
        property :shift_200 do
          key :type, :float
          key :description, 'Valuation estimate of advance with parallel-interest rate movement of plus 200 basis points'
        end
        property :shift_300 do
          key :type, :float
          key :description, 'Valuation estimate of advance with parallel-interest rate movement of plus 300 basis points'
        end
      end
    end
  end
end