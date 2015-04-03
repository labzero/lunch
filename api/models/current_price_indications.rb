module MAPI
  module Models
    class CurrentPriceIndicationsVrc
      include Swagger::Blocks
      swagger_model :CurrentPriceIndicationsVrc do
        property :advance_maturity do
          key :type, :string
          key :description, 'Advance Maturity Type'
        end
        property :overnight_fed_funds_benchmark do
          key :type, :number
          key :description, 'Overnight Fed Funds Benchmark'
        end
        property :basis_point_spread_to_benchmark do
          key :type, :number
          key :description, 'Basis Point Spread To Benchmark'
        end
        property :advance_rate do
          key :type, :number
          key :description, 'Advance Rate'
        end
      end
    end
    class CurrentPriceIndicationsFrc
      include Swagger::Blocks
      swagger_model :CurrentPriceIndicationsFrc do
        property :advance_maturity do
          key :type, :string
          key :description, 'Advance Maturity Type'
        end
        property :treasury_benchmark_maturity do
          key :type, :string
          key :description, 'Treasury Benchmark Maturity Type'
        end
        property :nominal_yield_of_benchmark do
          key :type, :number
          key :description, 'Nominal Yield of Benchmark'
        end
        property :basis_point_spread_to_benchmark do
          key :type, :number
          key :description, 'Basis Point Spread To Benchmark'
        end
        property :advance_rate do
          key :type, :number
          key :description, 'Advance Rate'
        end
      end
      end
    class CurrentPriceIndicationsArc
      include Swagger::Blocks
      swagger_model :CurrentPriceIndicationsArc do
        property :advance_maturity do
          key :type, :string
          key :description, 'Advance Maturity Type'
        end
        property :'1_month_libor' do
          key :type, :number
          key :description, '1-Month LIBOR'
        end
        property :'3_month_libor' do
          key :type, :number
          key :description, '3-Month LIBOR'
        end
        property :'6_month_libor' do
          key :type, :number
          key :description, '6-Month LIBOR'
        end
        property :prime do
          key :type, :number
          key :description, 'Daily Prime Rate'
        end
      end
    end
  end
end