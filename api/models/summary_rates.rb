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
        property :start_of_day_rate do
          key :type, :number
          key :format, :float
          key :description, 'The rate of this loan_term and loan_type at the start of the day'
        end
        property :rate_change_bps do
          key :type, :number
          key :format, :float
          key :description, 'The difference between the current rate and the start of day rate, given in basis points'
          key :notes, 'Currently returning a float, which allows the possibility of fractional basis points'
        end
        property :end_of_day do
          key :type, :boolean
          key :description, 'Has this particular product reached end-of-day?'
        end
        property :rate_band_info do
          key :type, :RateBandInfoObject
          key :description, 'A hash containing information about the rate bands for this loan type and term'
        end
        property :disabled do
          key :type, :boolean
          key :description, 'A boolean indicating whether the rate has been disabled'
        end
        property :end_of_day do
          key :type, :boolean
          key :description, 'A boolean indicating whether the rate has reached its end of day shutoff'
        end
      end
      swagger_model :RateBandInfoObject do
        property :low_band_warn_delta do
          key :type, :number
          key :format, :float
          key :description, 'The change (in percent) between the start of day rate and the current rate at which a warning will be raised, on the low end.'
        end
        property :low_band_off_delta do
          key :type, :number
          key :format, :float
          key :description, 'The change (in percent) between the start of day rate and the current rate at which the rate will be shut off, on the low end.'
        end
        property :high_band_warn_delta do
          key :type, :number
          key :format, :float
          key :description, 'The change (in percent) between the start of day rate and the current rate at which a warning will be raised, on the high end.'
        end
        property :high_band_off_delta do
          key :type, :number
          key :format, :float
          key :description, 'The change (in percent) between the start of day rate and the current rate at which the rate will be shut off, on the high end.'
        end
        property :low_band_warn_rate do
          key :type, :number
          key :format, :float
          key :description, 'The rate at which a warning will be raised, on the low end.'
        end
        property :low_band_off_rate do
          key :type, :number
          key :format, :float
          key :description, 'The rate at which the rate will be shut off, on the low end.'
        end
        property :high_band_warn_rate do
          key :type, :number
          key :format, :float
          key :description, 'The rate at which a warning will be raised, on the high end.'
        end
        property :high_band_off_rate do
          key :type, :number
          key :format, :float
          key :description, 'The rate at which the rate will be shut off, on the high end.'
        end
        property :min_threshold_exceeded do
          key :type, :boolean
          key :description, 'A boolean signifying whether the low_band_off_rate has been exceeded'
        end
        property :max_threshold_exceeded do
          key :type, :boolean
          key :description, 'A boolean signifying whether the high_band_off_rate has been exceeded'
        end
        property :min_warning_exceeded do
          key :type, :boolean
          key :description, 'A boolean signifying whether the low_band_warn_rate has been exceeded'
        end
        property :max_warning_exceeded do
          key :type, :boolean
          key :description, 'A boolean signifying whether the high_band_warn_rate has been exceeded'
        end
      end
    end
  end
end
