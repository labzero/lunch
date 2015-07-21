module MAPI
  module Models
    class MemberInterestRateResets
      include Swagger::Blocks
      swagger_model :MemberInterestRateResets do
        property :date_processed do
          key :type, :date
          key :description, 'The last date on which interest rate resets were processed'
        end
        property :resets do
          key :type, :array
          key :description, 'An array of interest rate reset objects.'
          items do
            key :'$ref', :InterestRateResetObject
          end
        end
      end
      swagger_model :InterestRateResetObject do
        key :required, [:effective_date, :advance_number, :prior_rate, :new_rate, :next_reset]
        property :effective_date do
          key :type, :date
          key :description, 'Effective date of interest rate reset'
        end
        property :advance_number do
          key :type, :string
          key :description, 'The advance number for the interest rate reset'
        end
        property :prior_rate do
          key :type, :float
          key :description, 'The rate prior to the reset'
        end
        property :new_rate do
          key :type, :float
          key :description, 'The rate after the reset'
        end
        property :next_reset do
          key :type, :date
          key :description, 'The date of the next reset'
        end
      end
    end
  end
end