module MAPI
  module Models
    class MemberCapitalStockAndLeverage
      include Swagger::Blocks
      swagger_model :MemberCapitalStockAndLeverage do
        property :stock_owned do
          key :type, :integer
          key :description, 'Total dollar amount of stock owned, in full dollars'
        end
        property :minimum_requirement do
          key :type, :integer
          key :description, 'The minimum capital stock position requirement, in whole dollar amount'
        end
        property :excess_stock do
          key :type, :integer
          key :description, 'The excess capital stock, in whole dollar amount'
        end
        property :surplus_stock do
          key :type, :integer
          key :description, 'The surplus capital stock, in whole dollar amount, calculated as follows: stock_owned - [minimum_requirement x 115% (rounded to the next $100)] '
        end
        property :activity_based_requirement do
          key :type, :integer
          key :description, 'The activity-based capital stock position requirement, in whole dollar amount'
        end
        property :remaining_stock do
          key :type, :integer
          key :description, 'The remaining capital stock, in whole dollar amount'
        end
        property :remaining_leverage do
          key :type, :integer
          key :description, 'The remaining leverage, in whole dollar amount'
        end
      end
    end
  end
end