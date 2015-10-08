module MAPI
  module Services
    module Member
      module CapitalStockAndLeverage
        def self.capital_stock_and_leverage(app, member_id)
          if app.settings.environment == :production
            cap_stock_member_details_query = <<-SQL
              SELECT
                FHLB_ID,
                NVL(TOTAL_CAPITAL_STOCK,0) TOTAL_CAPITAL_STOCK,
                (NVL(ADVANCES_OUTS_EOD,0) - (NVL(REG_ADV_MAT_TDY_TRM,0) + NVL(SBC_MATURING_TDY_TRM,0)) - (NVL(REG_ADV_MAT_TDY_ON,0) + NVL(SBC_MATURING_TDY_ON,0)) + (NVL(REG_ADV_FUND_TDY,0)+NVL(SBC_ADV_FUND_TDY,0)) + NVL(AT_ADV_FUNDING,0) - NVL(ADVANCES_REPAYS,0) - NVL(ADVANCES_AMORTS,0) - NVL(ADVANCES_PARTIAL_PREPAY,0)) ADVANCES_OUTS,
                (NVL(MPF_UNPAID_BALANCE,0) + NVL(MPF_ACTIVITY,0)) TOT_MPF,
                NVL(MRTG_RELATED_ASSETS, 0) MORTGAGE_RELATED_ASSETS
               FROM CR_MEASURES.FINAN_SUMMARY_DATA_INTRADAY_V
               WHERE FHLB_ID = #{ ActiveRecord::Base.connection.quote(member_id)}
            SQL
            cap_stock_member_details_cursor = ActiveRecord::Base.connection.execute(cap_stock_member_details_query)
            cap_stock_member_details = {}
            while row = cap_stock_member_details_cursor.fetch_hash()
              cap_stock_member_details = row.with_indifferent_access
              break
            end

            cap_stock_requirements_query = <<-SQL
              SELECT ADVANCES_PCT, MPF_PCT, SURPLUS_PCT
              FROM QTL_APP.CAP_STOCK_REQ_PARAM
            SQL
            cap_stock_requirements_cursor = ActiveRecord::Base.connection.execute(cap_stock_requirements_query)
            cap_stock_requirements = {}
            while row = cap_stock_requirements_cursor.fetch_hash()
              cap_stock_requirements = row.with_indifferent_access
              break
            end

            return nil if cap_stock_requirements.blank?
            return {
              stock_owned: nil,
              minimum_requirement: nil,
              excess_stock: nil,
              surplus_stock:nil,
              activity_based_requirement: nil,
              remaining_stock: nil,
              remaining_leverage: nil
            } if cap_stock_member_details.blank?

            # define vars
            advances_percentage = cap_stock_requirements[:ADVANCES_PCT].to_f
            total_capital_stock = cap_stock_member_details[:TOTAL_CAPITAL_STOCK].to_i
            unrounded_adv_and_mpf_stock_requirement = (cap_stock_member_details[:TOT_MPF].to_i * cap_stock_requirements[:MPF_PCT].to_f) + (cap_stock_member_details[:ADVANCES_OUTS].to_i * advances_percentage)
            adv_and_mpf_stock_requirement = (unrounded_adv_and_mpf_stock_requirement / 100).ceil * 100
            mav_stock_requirement = (cap_stock_member_details[:MORTGAGE_RELATED_ASSETS].to_i / 100).ceil * 100

            # Capital Stock Requirement Calculation
            minimum_stock_requirement = adv_and_mpf_stock_requirement > mav_stock_requirement ? adv_and_mpf_stock_requirement : mav_stock_requirement

            # Stock Purchase Requirement Calculation
            excess_deficiency = total_capital_stock - minimum_stock_requirement

            # Unused Stock Calculation - report 0 if less held than required
            unused_stock = total_capital_stock > adv_and_mpf_stock_requirement ? (total_capital_stock - adv_and_mpf_stock_requirement) : 0

            # Additional Funding Possible
            additional_advances = advances_percentage > 0 ? (unused_stock / advances_percentage).floor : 0
            surplus_stock = ((total_capital_stock - (minimum_stock_requirement * cap_stock_requirements[:SURPLUS_PCT].to_f)) / 100).ceil * 100

            {
              stock_owned: (total_capital_stock.to_i if total_capital_stock),
              minimum_requirement: (minimum_stock_requirement.to_i if minimum_stock_requirement),
              excess_stock: (excess_deficiency.to_i if excess_deficiency),
              surplus_stock: (surplus_stock.to_i if surplus_stock),
              activity_based_requirement: (adv_and_mpf_stock_requirement.to_i if adv_and_mpf_stock_requirement),
              remaining_stock: ((total_capital_stock.to_i - adv_and_mpf_stock_requirement.to_i) if total_capital_stock && adv_and_mpf_stock_requirement),
              remaining_leverage: (additional_advances.to_i if additional_advances)
            }.with_indifferent_access
          else
            JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'capital_stock_and_leverage.json'))).with_indifferent_access
          end
        end
      end
    end
  end
end