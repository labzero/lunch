module MAPI
  module Models
    class PriceIndicationHistorical
      include Swagger::Blocks
      swagger_model :PriceIndicationHistorical do
        property :start_date do
          key :type, :date
          key :description, 'Selected Start Date for the historical price indication rate'
        end
        property :end_date do
          key :type, :date
          key :description, 'Selected End Date for the historical price indication rate'
        end
        property :collateral_type do
          key :type, :string
          key :description, 'An object containing collateral type relevant to the specified loan_type'
          key :enum, [:standard, :sbc]
        end
        property :credit_type do
          key :type, :string
          key :description, 'An object containing the selected credit type the collateral'
          key :enum, [:vrc, :frc, :'1m_libor', :'3m_libor', :'6m_libor', :daily_prime]
        end
        property :rates_by_date do
          key :type, :RatesByDateObject
          key :description, 'An object containing date for the rates and the rates object for each dates'
        end
      end
      swagger_model :RatesByDateObject do
        property :date do
          key :type, :Date
          key :description, 'Dates for the quoted rates'
        end
        property :rates_by_term do
          key :type, :RatesBytermObject
          key :description, 'An object containing the rates information'
        end
      end
      swagger_model :RatesBytermObject do
        property :term do
          key :type, :string
          key :description, 'Terms for the rates i.e. 1D, 1M, 3M, 1Y etc'
        end
        property :type do
          key :type, :string
          key :description, 'The type of value being returned. Either a `rate` or a `basis_point`'
        end
        property :value do
          key :type, :Fixnum
          key :description, 'The value being returned. Either a rate or a basis_point'
        end
        property :day_count_basis do
          key :type, :string
          key :description, 'Day Count Basis description'
        end
        property :pay_freq do
          key :type, :string
          key :description, 'Payment Frequency description'
        end
      end
    end
  end
end
