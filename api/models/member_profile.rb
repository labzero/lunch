module MAPI
  module Models
    class MemberFinancialProfile
      include Swagger::Blocks
      swagger_model :MemberFinancialProfileStandardBorrowingCapacity do
        key :required, [:total, :remaining]
        property :total do
          key :type, :integer
          key :description, 'The total standard borrowing capacity.'
        end
        property :remaining do
          key :type, :integer
          key :description, 'The remaining standard borrowing capacity.'
        end
      end
      swagger_model :MemberFinancialProfileSBCBorrowingCapacity do
        key :required, [:total_borrowing, :remaining_borrowing, :total_market, :remaining_market]
        property :total_borrowing do
          key :type, :integer
          key :description, 'The total securities backed borrowing capacity.'
        end
        property :remaining_borrowing do
          key :type, :integer
          key :description, 'The remaining securities backed borrowing capacity.'
        end
        property :total_market do
          key :type, :integer
          key :description, 'The total securities backed borrowing capacity market value.'
        end
        property :remaining_market do
          key :type, :integer
          key :description, 'The remaining securities backed borrowing capacity market value.'
        end
      end
      swagger_model :MemberFinancialProfileBorrowingCapacity do
        key :required, [:total, :remaining, :standard, :sbc]
        property :total do
          key :type, :integer
          key :description, 'The total collateral based borrowing capacity.'
        end
        property :remaining do
          key :type, :integer
          key :description, 'The remaining collateral based borrowing capacity.'
        end
        property :standard do
          key :type, :MemberFinancialProfileStandardBorrowingCapacity
          key :description, 'The standard borrowing capacity summary.'
        end
        property :sbc do
          key :type, :MemberFinancialProfileSBCBorrowingCapacity
          key :description, 'The securitied backed borrowing capacity summary.'
        end
      end
      swagger_model :MemberFinancialProfileCreditOutstanding do
        key :required, [:total, :standard, :sbc, :swaps_credit, :swaps_notational, :mpf_credit, :letters_of_credit, :investments]
        property :total do
          key :type, :integer
          key :description, 'The total outstanding credit.'
        end
        property :standard do
          key :type, :integer
          key :description, 'The total outstanding credit backed by standard collateral.'
        end
        property :sbc do
          key :type, :integer
          key :description, 'The total outstanding credit backed by securties.'
        end
        property :swaps_credit do
          key :type, :integer
          key :description, 'The total outstanding credit swaps.'
        end
        property :swaps_notational do
          key :type, :integer
          key :description, 'The total outstanding notational swaps.'
        end
        property :mpf_credit do
          key :type, :integer
          key :description, 'The total outstanding MPF credit.'
        end
        property :letters_of_credit do
          key :type, :integer
          key :description, 'The total outstanding letters of credit.'
        end
        property :investments do
          key :type, :integer
          key :description, 'The total outstanding investments.'
        end
      end
      swagger_model :MemberFinancialProfile do
        key :required, [
          :sta_balance, :total_financing_available, :remaining_financing_available,
          :mpf_credit_available, :collateral_market_value_sbc_agency, :collateral_market_value_sbc_aaa,
          :collateral_market_value_sbc_aa
        ]
        property :sta_balance do
          key :type, :number
          key :description, 'STA balance for the member for the prior day.'
        end
        property :total_financing_available do
          key :type, :integer
          key :description, 'The total financing available.'
        end
        property :remaining_financing_available do
          key :type, :integer
          key :description, 'The unused financing available.'
        end
        property :mpf_credit_available do
          key :type, :integer
          key :description, 'The MPF credit available.'
        end
        property :collateral_market_value_sbc_agency do
          key :type, :integer
          key :description, 'The market value of the securities backed Agency collateral.'
        end
        property :collateral_market_value_sbc_aaa do
          key :type, :integer
          key :description, 'The market value of the securities backed AAA collateral.'
        end
        property :collateral_market_value_sbc_aa do
          key :type, :integer
          key :description, 'The market value of the securities backed AAA collateral.'
        end
        property :total_borrowing_capacity_standard do
          key :type, :integer
          key :description, 'The total borrowing capacity of standard collateral.'
        end
        property :total_borrowing_capacity_sbc_agency do
          key :type, :integer
          key :description, 'The total borrowing capacity of securities backed Agency collateral.'
        end
        property :total_borrowing_capacity_sbc_aaa do
          key :type, :integer
          key :description, 'The total borrowing capacity of securities backed AAA collateral.'
        end
        property :total_borrowing_capacity_sbc_aa do
          key :type, :integer
          key :description, 'The total borrowing capacity of securities backed AA collateral.'
        end
        property :total_borrowing_capacity_sbc_aa do
          key :type, :integer
          key :description, 'The total borrowing capacity of securities backed AA collateral.'
        end
        property :collateral_delivery_status do
          key :type, :string
          key :description, 'The collateral delivery status (Y if collatreal delivery is required, N if its not).'
        end
        property :financing_percentage do
          key :type, :integer
          key :description, 'The percentage of assets avaiable for borrowing.'
        end
        property :maximum_term do
          key :type, :integer
          key :description, 'The maximum term the member can borrow for, in months.'
        end
        property :total_assets do
          key :type, :integer
          key :description, 'The total asset value for the member.'
        end
        property :approved_long_term_credit do
          key :type, :integer
          key :description, 'How much credit is available for terms over 5 years.'
        end
        property :forward_commitments do
          key :type, :integer
          key :description, 'The total value of the members forward commitments.'
        end
        property :collateral_borrowing_capacity do
          key :type, :MemberFinancialProfileBorrowingCapacity
          key :description, 'The collateral backed borrowing capacity summary.'
        end
        property :credit_outstanding do
          key :type, :MemberFinancialProfileCreditOutstanding
          key :description, 'The credit outstanding summary for the member.'
        end
        property :capital_stock do
          key :type, :MemberCapitalStockAndLeverage
          key :description, 'The capital stock and leverage summary.'
        end
      end
    end
  end
end
