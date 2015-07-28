module MAPI
  module Services
    module Member
      module Profile
        MEMBER_LIST_QUERY = <<-SQL
          select web_adm.web_member_data.FHLB_ID, web_adm.web_member_data.CP_ASSOC
          from web_adm.web_member_data
          where web_adm.web_member_data.CP_ASSOC is not null -- this is redundent given the table doesn't allow nulls in this column
        SQL

        def self.member_profile(app, member_id)
          member_id = member_id.to_i
          quoted_member_id = ActiveRecord::Base.connection.quote(member_id)

          member_position_connection_string = <<-SQL
          SELECT
          DELIVERY_STATUS_FLAG,
          RECOM_EXPOSURE_PCT,
          MAX_TERM,
          TOTAL_ASSETS,
          RHFA_ADVANCES_LIMIT,
          REG_ADVANCES_OUTS,
          SBC_ADVANCES_OUTS,
          SWAP_MARKET_OUTS,
          SWAP_NOTIONAL_PRINCIPAL,
          UNSECURED_CREDIT,
          LCS_OUTS,
          MPF_CE_COLLATERAL_REQ,
          STX_LEDGER_BALANCE,
          (NVL(REG_ADVANCES_OUTS, 0)  +
            NVL(SBC_ADVANCES_OUTS, 0) +
            NVL(SWAP_MARKET_OUTS, 0) +
            NVL(UNSECURED_CREDIT, 0) +
            NVL(LCS_OUTS, 0)  +
            NVL(MPF_CE_COLLATERAL_REQ, 0)
          ) AS CREDIT_OUTSTANDING,
          COMMITTED_FUND_LESS_MPF,
          AVAILABLE_CREDIT,
          RECOM_EXPOSURE,
          REG_BORR_CAP,
          SBC_BORR_CAP,
          EXCESS_REG_BORR_CAP,
          EXCESS_SBC_BORR_CAP_AG,
          EXCESS_SBC_BORR_CAP_AAA,
          EXCESS_SBC_BORR_CAP_AA,
          EXCESS_SBC_BORR_CAP,
          SBC_MARKET_VALUE_AG,
          SBC_MARKET_VALUE_AAA,
          SBC_MARKET_VALUE_AA,
          SBC_MARKET_VALUE,
          EXCESS_SBC_MARKET_VALUE,
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
          WHERE fhlb_id = #{quoted_member_id}
          SQL

          member_sta_cursor_string = <<-SQL
            SELECT
            STX_CURRENT_LEDGER_BALANCE
            FROM PORTFOLIOS.STA e, PORTFOLIOS.STA_TRANS f
            WHERE e.STA_ACCOUNT_TYPE = 1
            AND  f.STA_ID = e.STA_ID AND e.fhlb_id = #{quoted_member_id}
            AND f.STX_UPDATE_DATE =
            (SELECT MAX(STX_UPDATE_DATE) FROM PORTFOLIOS.STA_TRANS)
          SQL

          if app.settings.environment == :production
            member_position_hash = ActiveRecord::Base.connection.execute(member_position_connection_string).fetch_hash()
            member_sta_hash = ActiveRecord::Base.connection.execute(member_sta_cursor_string).fetch_hash()
          else
            member_position_hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_financial_position.json'))).sample
            member_sta_hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_sta_balances.json'))).sample
          end
          capital_stock_and_leverage = MAPI::Services::Member::CapitalStockAndLeverage::capital_stock_and_leverage(app, member_id)

          if capital_stock_and_leverage.nil? || member_sta_hash.nil? || member_position_hash.nil?
            return nil
          end

          standard_borrowing_capacity = member_position_hash['REG_BORR_CAP'].to_i
          standard_borrowing_capacity_remaining = member_position_hash['EXCESS_REG_BORR_CAP'].to_i
          sbc_borrowing_capacity = member_position_hash['SBC_BORR_CAP'].to_i
          sbc_borrowing_capacity_remaining = member_position_hash['EXCESS_SBC_BORR_CAP'].to_i
          total_financing_available = member_position_hash['RECOM_EXPOSURE'].to_i
          remaining_financing_available = member_position_hash['AVAILABLE_CREDIT'].to_i
          total_credit_outstanding = member_position_hash['CREDIT_OUTSTANDING'].to_i
          forward_commitments = member_position_hash['COMMITTED_FUND_LESS_MPF'].to_i
          mpf_credit_available = total_financing_available - (total_credit_outstanding + forward_commitments + remaining_financing_available)

          {
            sta_balance: member_sta_hash['STX_CURRENT_LEDGER_BALANCE'].to_f,
            total_financing_available: total_financing_available,
            remaining_financing_available: remaining_financing_available,
            mpf_credit_available: mpf_credit_available,
            collateral_market_value_sbc_agency: member_position_hash['SBC_MARKET_VALUE_AG'].to_i,
            collateral_market_value_sbc_aaa: member_position_hash['SBC_MARKET_VALUE_AAA'].to_i,
            collateral_market_value_sbc_aa: member_position_hash['SBC_MARKET_VALUE_AA'].to_i,
            total_borrowing_capacity_standard: member_position_hash['EXCESS_REG_BORR_CAP'].to_i,
            total_borrowing_capacity_sbc_agency: member_position_hash['EXCESS_SBC_BORR_CAP_AG'].to_i,
            total_borrowing_capacity_sbc_aaa: member_position_hash['EXCESS_SBC_BORR_CAP_AAA'].to_i,
            total_borrowing_capacity_sbc_aa: member_position_hash['EXCESS_SBC_BORR_CAP_AA'].to_i,
            collateral_delivery_status: member_position_hash['DELIVERY_STATUS_FLAG'].to_s,
            financing_percentage: member_position_hash['RECOM_EXPOSURE_PCT'].to_f,
            maximum_term: member_position_hash['MAX_TERM'].to_i,
            total_assets: member_position_hash['TOTAL_ASSETS'].to_i,
            approved_long_term_credit: member_position_hash['RHFA_ADVANCES_LIMIT'].to_f,
            forward_commitments: forward_commitments,
            collateral_borrowing_capacity: {
              total: standard_borrowing_capacity + sbc_borrowing_capacity,
              remaining: standard_borrowing_capacity_remaining + sbc_borrowing_capacity_remaining,
              standard: {
                total: standard_borrowing_capacity,
                remaining: standard_borrowing_capacity_remaining
              },
              sbc: {
                total_borrowing: sbc_borrowing_capacity,
                remaining_borrowing: sbc_borrowing_capacity_remaining,
                total_market: member_position_hash['SBC_MARKET_VALUE'].to_i,
                remaining_market: member_position_hash['EXCESS_SBC_MARKET_VALUE'].to_i
              }
            },
            credit_outstanding: {
              total: total_credit_outstanding,
              standard: member_position_hash['REG_ADVANCES_OUTS'].to_i,
              sbc: member_position_hash['SBC_ADVANCES_OUTS'].to_i,
              swaps_credit: member_position_hash['SWAP_MARKET_OUTS'].to_i,
              swaps_notational: member_position_hash['SWAP_NOTIONAL_PRINCIPAL'].to_i,
              mpf_credit: member_position_hash['MPF_CE_COLLATERAL_REQ'].to_i,
              letters_of_credit: member_position_hash['LCS_OUTS'].to_i,
              investments: member_position_hash['UNSECURED_CREDIT'].to_i
            },
            capital_stock: capital_stock_and_leverage
          }
        end

        def self.member_details(app, member_id)
          quoted_member_id = ActiveRecord::Base.connection.quote(member_id)
          fhfb_number = nil
          sta_number = nil
          member_name = nil

          member_name_query = <<-SQL
            SELECT web_adm.web_member_data.CP_ASSOC
            FROM web_adm.web_member_data
            WHERE web_adm.web_member_data.FHLB_ID = #{quoted_member_id}
          SQL

          sta_number_query = <<-SQL
            SELECT
            sta.sta_account_number
            FROM 
            portfolios.sta sta,
            portfolios.sta_trans st
            where sta.fhlb_id = #{quoted_member_id}
            AND sta.sta_id = st.sta_id
            AND sta.sta_account_type = 1
            AND TRUNC(st.stx_update_date) = (SELECT TRUNC(MAX(stx_update_date))  FROM  portfolios.sta_trans)
          SQL

          fhfb_number_query = <<-SQL
            SELECT cu_fhfb_id FROM portfolios.customers WHERE fhlb_id = #{quoted_member_id}
          SQL

          if app.settings.environment == :production
            member_name = ActiveRecord::Base.connection.execute(member_name_query).fetch.try(&:first)
            sta_number = ActiveRecord::Base.connection.execute(sta_number_query).fetch.try(&:first)
            fhfb_number = ActiveRecord::Base.connection.execute(fhfb_number_query).fetch.try(&:first)
          else
             member = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_details.json')))[member_id.to_s]
             member_name = member['name'] if member
             fhfb_number = member['fhfb_number'] if member
             sta_number = member['sta_number'] if member
          end
          
          return nil if member_name.nil? || sta_number.nil? || fhfb_number.nil?

          {
            name: member_name,
            fhfb_number: fhfb_number,
            sta_number: sta_number
          }

        end

        def self.member_list(app)
          members = []
          if app.settings.environment == :production
            member_query_cursor = ActiveRecord::Base.connection.execute(MEMBER_LIST_QUERY)
            while row = member_query_cursor.fetch_hash()
              members << row
            end
          else
            members = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_list.json')))
          end
          ((members.sort {|a, b| a['CP_ASSOC'] <=> b['CP_ASSOC']}).collect {|member| {id: member['FHLB_ID'].to_i, name: member['CP_ASSOC'].to_s} }).to_json
        end

        def self.member_contacts(app, member_id)
          member_id = member_id.to_i
          quoted_member_id = ActiveRecord::Base.connection.quote(member_id)

          if app.settings.environment == :production
            # Collateral Asset Manager - TODO: pull in phone number for CAM once it's location (e.g. database) has been determined
            cam_query = <<-SQL
              select customer_master_id as fhlb_id, cs_user_id as USERNAME,  user_first_name || ' ' || user_last_name as FULL_NAME, email as EMAIL
              from fhlbown.customer_profile@colaprod_link p, fhlbown.v_cs_user_profile@colaprod_link c
              Where c.cs_user_id = p.collateral_analyst and customer_master_id = #{quoted_member_id}
            SQL
            cam = ActiveRecord::Base.connection.execute(cam_query).fetch_hash || {}

            # Relationship Manager
            rm_query = <<-SQL
              select c.fhlb_id, MR_FIRST || ' ' || MR_LAST as FULL_NAME, MR_PHONE as PHONE_NUMBER, MR_EMAIL as EMAIL
              from PORTFOLIOS.CUSTOMERS C, PORTFOLIOS.MARKETING_REPS R
              where R.MR_INITIALS = C.CU_MARKETING_REP and fhlb_id = #{quoted_member_id}
            SQL
            rm = ActiveRecord::Base.connection.execute(rm_query).fetch_hash || {}
          else
            cam = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_contacts.json')))['CAM']
            rm = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_contacts.json')))['RM']
          end
          rm['USERNAME'] = rm['EMAIL'].match(/^(.+?)@/).captures.first.downcase if rm['EMAIL'].match(/^(.+?)@/)
          cam['USERNAME'] = cam['USERNAME'].downcase if cam['USERNAME']
          {
            cam: cam,
            rm: rm
          }
        end
      end
    end
  end
end
