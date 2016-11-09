module MAPI
  module Models
    class CurrentPriceIndicationsVrc
      include Swagger::Blocks
      swagger_model :CurrentPriceIndicationsVrc do
        property :advance_maturity do
          key :type, :string
          key :description, 'Advance Maturity Type'
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