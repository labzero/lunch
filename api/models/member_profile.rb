module MAPI
  module Models
    class MemberFinancialProfile
      include Swagger::Blocks
      swagger_model :MemberFinancialProfile do
        property :sta_balance do
          key :type, :Numeric
          key :description, 'STA balance for the member for the prior day.  Could be null as returned from database'
        end
        property :credit_outstanding do
          key :type, :integer
          key :description, 'Intraday Credit Outstanding. '
        end
        property :financial_available do
          key :type, :integer
          key :description, 'Intraday Financial Available.  Could be null as returned from database'
        end
        property :stock_leverage do
          key :type, :integer
          key :description, 'Intraday Stock Leverage amount. May be null as returned from Capital Stock Calculation services.'
        end
        property :collateral_market_value_sbc_agency do
          key :type, :integer
          key :description, 'Intraday SBC Agency Collateral Market Value.  Could be null as returned from database'
        end
        property :collateral_market_value_sbc_aaa do
          key :type, :integer
          key :description, 'Intraday SBC AAA Collateral Market Value.  Could be null as returned from database'
        end
        property :collateral_market_value_sbc_aa do
          key :type, :integer
          key :description, 'Intraday SBC AA Collateral Market Value.  Could be null as returned from database'
        end
        property :borrowing_capacity_standard do
          key :type, :integer
          key :description, 'Intraday Standard Collateral Borrowing Capacity Value.  Could be null as returned from database'
        end
        property :borrowing_capacity_sbc_agency do
          key :type, :integer
          key :description, 'Intraday SBC Agency Collateral Borrowing Capacity Value.  Could be null as returned from database'
        end
        property :borrowing_capacity_sbc_aaa do
          key :type, :integer
          key :description, 'Intraday SBC AAA Collateral Borrowing Capacity Value.  Could be null as returned from database'
        end
        property :borrowing_capacity_sbc_aa do
          key :type, :integer
          key :description, 'Intraday SBC AA Collateral Borrowing Capacity Value.  Could be null as returned from database'
        end
      end
    end
  end
end
