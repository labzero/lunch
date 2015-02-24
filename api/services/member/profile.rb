module MAPI
  module Services
    module Member
      module Profile
        def self.member_profile(app, member_id)
          member_id = member_id.to_i

          member_position_connection_string = <<-SQL
          SELECT
          STX_LEDGER_BALANCE,
          (NVL(REG_ADVANCES_OUTS, 0)  +
            NVL(SBC_ADVANCES_OUTS, 0) +
            NVL(SWAP_MARKET_OUTS, 0) +
            NVL(UNSECURED_CREDIT, 0) +
            NVL(LCS_OUTS, 0)  +
            NVL(MPF_CE_COLLATERAL_REQ, 0)
          ) AS CREDIT_OUTSTANDING,
          AVAILABLE_CREDIT as FINANCIAL_AVAILABLE,
          EXCESS_REG_BORR_CAP,
          EXCESS_SBC_BORR_CAP_AG,
          EXCESS_SBC_BORR_CAP_AAA,
          EXCESS_SBC_BORR_CAP_AA,
          SBC_MARKET_VALUE_AG,
          SBC_MARKET_VALUE_AAA,
          SBC_MARKET_VALUE_AA,
          (
            (NVL(ADVANCES_OUTS_EOD, 0) -
            (NVL(REG_ADV_MAT_TDY_TRM, 0) + NVL(SBC_MATURING_TDY_TRM, 0)) -
            (NVL(REG_ADV_MAT_TDY_ON, 0) + NVL(SBC_MATURING_TDY_ON, 0)) +
            (NVL(REG_ADV_FUND_TDY, 0) + NVL(SBC_ADV_FUND_TDY, 0)) +
             NVL(AT_ADV_FUNDING, 0) -
             NVL(ADVANCES_REPAYS, 0) +
             NVL(MPF_ACTIVITY, 0) +
             NVL(MPF_UNPAID_BALANCE, 0) -
             NVL(ADVANCES_AMORTS, 0) -
             NVL(ADVANCES_PARTIAL_PREPAY, 0)) -
             (NVL(MPF_ACTIVITY, 0)  - NVL(MPF_UNPAID_BALANCE, 0))
          ) AS ADVANCES_OUTSTANDING,
          (NVL(MPF_ACTIVITY, 0)  - NVL(MPF_UNPAID_BALANCE, 0)) as MPF_UNPAID_BALANCE,
          TOTAL_CAPITAL_STOCK,
          MRTG_RELATED_ASSETS,
          DECODE(trunc(MRTG_RELATED_ASSETS/100)  * 100,
                 MRTG_RELATED_ASSETS, trunc(MRTG_RELATED_ASSETS/100)  * 100,
                 (trunc(MRTG_RELATED_ASSETS/100)  * 100) + 100) as MRTG_RELATED_ASSETS_round100
          FROM CR_MEASURES.FINAN_SUMMARY_DATA_INTRADAY_V
          WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
          SQL

          member_sta_cursor_string = <<-SQL
            SELECT
            STA_ACCOUNT_NUMBER,
            STX_UPDATE_DATE,
            STX_CURRENT_LEDGER_BALANCE,
            STX_INT_RATE,
            FROM PORTFOLIOS.STA e, PORTFOLIOS.STA_TRANS f
            WHERE e.STA_ACCOUNT_TYPE = 1
            AND  f.STA_ID = e.STA_ID AND e.fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
            AND f.STX_UPDATE_DATE =
            (SELECT MAX(STX_UPDATE_DATE) FROM PORTFOLIOS.STA_TRANS WHERE FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)})
          SQL

          if app.settings.environment == :production
            member_position_hash  = {}
            member_sta_hash  = {}
            member_position_cursor = ActiveRecord::Base.connection.execute(member_position_connection_string)
            while row = member_position_cursor.fetch_hash()
              member_position_hash  = row
              break
            end
            member_sta_cursor_string = ActiveRecord::Base.connection.execute(member_position_connection_string)
            while row = member_sta_cursor_string.fetch_hash()
              member_sta_hash  = row
              break
            end
          else
            member_position_hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_financial_position.json'))).sample
            member_sta_hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_sta_balances.json'))).sample
          end
          stock_leverage = nil
          # get the 4 values from member position and pass into capital stock services to get the stock_leverage value
          if member_position_hash.count > 0
            total_cap_stock = member_position_hash['TOTAL_CAPITAL_STOCK']|| 0
            advances_outstanding = member_position_hash['ADVANCES_OUTSTANDING']|| 0
            mpf_unpaid_balance = member_position_hash['MPF_UNPAID_BALANCE']|| 0
            mortgage_related_assets = member_position_hash['MRTG_RELATED_ASSETS']|| 0
            capital_stock_returns = MAPI::Shared::CapitalStockServices::capital_stock_requirements(total_cap_stock, advances_outstanding, mpf_unpaid_balance, mortgage_related_assets, app.settings.environment)
            if capital_stock_returns.count > 0
              if capital_stock_returns['additional_advances']
                stock_leverage = capital_stock_returns['additional_advances'].to_i
              else
                stock_leverage = capital_stock_returns['additional_advances']
              end
             else
              Rails.logger.warn("MAPI::Shared::CapitalStockServices error. Not returning values")
            end
          end
          {
            sta_balance: (member_sta_hash['STX_CURRENT_LEDGER_BALANCE'].to_f if member_sta_hash['STX_CURRENT_LEDGER_BALANCE']) ,
            credit_outstanding: (member_position_hash['CREDIT_OUTSTANDING'].to_i if member_position_hash['CREDIT_OUTSTANDING']) ,
            financial_available: (member_position_hash['FINANCIAL_AVAILABLE'].to_i if member_position_hash['FINANCIAL_AVAILABLE']),
            stock_leverage:stock_leverage,
            collateral_market_value_sbc_agency: (member_position_hash['SBC_MARKET_VALUE_AG'].to_i if member_position_hash['SBC_MARKET_VALUE_AG']),
            collateral_market_value_sbc_aaa: (member_position_hash['SBC_MARKET_VALUE_AAA'].to_i if member_position_hash['SBC_MARKET_VALUE_AAA']),
            collateral_market_value_sbc_aa: (member_position_hash['SBC_MARKET_VALUE_AA'].to_i if member_position_hash['SBC_MARKET_VALUE_AA']),
            borrowing_capacity_standard: (member_position_hash['EXCESS_REG_BORR_CAP'].to_i if member_position_hash['EXCESS_REG_BORR_CAP']),
            borrowing_capacity_sbc_agency: (member_position_hash['EXCESS_SBC_BORR_CAP_AG'].to_i if member_position_hash['EXCESS_SBC_BORR_CAP_AG']),
            borrowing_capacity_sbc_aaa: (member_position_hash['EXCESS_SBC_BORR_CAP_AAA'].to_i if member_position_hash['EXCESS_SBC_BORR_CAP_AAA']),
            borrowing_capacity_sbc_aa: (member_position_hash['EXCESS_SBC_BORR_CAP_AA'].to_i if member_position_hash['EXCESS_SBC_BORR_CAP_AA'])
          }.to_json
        end
      end
    end
  end
end
