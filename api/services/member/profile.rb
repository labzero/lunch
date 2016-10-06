module MAPI
  module Services
    module Member
      module Profile
        include MAPI::Shared::Utils
        MEMBER_LIST_QUERY = <<-SQL
          select web_adm.web_member_data.FHLB_ID, web_adm.web_member_data.CP_ASSOC
          from web_adm.web_member_data
          where web_adm.web_member_data.CP_ASSOC is not null -- this is redundent given the table doesn't allow nulls in this column
        SQL

        def self.member_profile(app, member_id)
          member_id = member_id.to_i
          member_position_connection_string = <<-SQL
          SELECT
          FHFB_ID,
          CQR_RATING,
          REPORTING_AGENCY,
          CREDIT_ANALYST,
          ADVANCES_OUTS_EOD,
          (NVL(REG_ADV_MAT_TDY_TRM, 0) + NVL(SBC_MATURING_TDY_TRM, 0)) as ADVANCES_MAT_TODAY_TERM,
          (NVL(REG_ADV_MAT_TDY_ON,0) + NVL(SBC_MATURING_TDY_ON,0)) as ADVANCES_MAT_TODAY_ON,
          (NVL(REG_ADV_FUND_TDY,0) + NVL(SBC_ADV_FUND_TDY,0)) as SCHEDULED_FUNDING_TODAY,
          ADVANCES_AMORTS,
          ADVANCES_PARTIAL_PREPAY,
          AT_ADV_FUNDING,
          ADVANCES_REPAYS,
          ADVANCES_OUTS,
          OTHER_CREDIT_PRODS,
          LT_ADV_OS,
          RHFA_AVAILABLE_LIMIT,
          MPF_ACTIVITY,
          MPF_UNPAID_BALANCE,
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
          SBC_BORR_CAP_AG,
          SBC_BORR_CAP_AAA,
          SBC_BORR_CAP_AA,
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
          EXCESS_SBC_MV_AG,
          EXCESS_SBC_MV_AAA,
          EXCESS_SBC_MV_AA,
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
          (NVL(MPF_ACTIVITY, 0) + NVL(MPF_UNPAID_BALANCE, 0)) as TOTAL_MPF,
          (NVL(MPF_ACTIVITY, 0) - NVL(MPF_UNPAID_BALANCE, 0)) as MPF_UNPAID_BALANCE,
          TOTAL_CAPITAL_STOCK,
          MRTG_RELATED_ASSETS,
          DECODE(trunc(MRTG_RELATED_ASSETS/100)  * 100,
                 MRTG_RELATED_ASSETS, trunc(MRTG_RELATED_ASSETS/100)  * 100,
                 (trunc(MRTG_RELATED_ASSETS/100)  * 100) + 100) as MRTG_RELATED_ASSETS_round100
          FROM CR_MEASURES.FINAN_SUMMARY_DATA_INTRADAY_V
          WHERE fhlb_id = #{quote(member_id)}
          SQL

          member_sta_cursor_string = <<-SQL
            SELECT
            STX_CURRENT_LEDGER_BALANCE, STX_UPDATE_DATE
            FROM PORTFOLIOS.STA e, PORTFOLIOS.STA_TRANS f
            WHERE e.STA_ACCOUNT_TYPE = 1
            AND  f.STA_ID = e.STA_ID AND e.fhlb_id = #{quote(member_id)}
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

          if capital_stock_and_leverage.nil? || member_position_hash.nil?
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
            member_id: member_id.to_i,
            sta_balance: member_sta_hash.nil? ? nil : member_sta_hash['STX_CURRENT_LEDGER_BALANCE'].to_f,
            sta_update_date: member_sta_hash.nil? ? nil : member_sta_hash['STX_UPDATE_DATE'].try(:to_date),
            total_financing_available: total_financing_available,
            remaining_financing_available: remaining_financing_available,
            mpf_credit_available: mpf_credit_available,
            collateral_delivery_status: member_position_hash['DELIVERY_STATUS_FLAG'].to_s,
            financing_percentage: member_position_hash['RECOM_EXPOSURE_PCT'].to_f * 100.0,
            maximum_term: member_position_hash['MAX_TERM'].to_i,
            total_assets: member_position_hash['TOTAL_ASSETS'].to_i,
            approved_long_term_credit: member_position_hash['RHFA_ADVANCES_LIMIT'].to_f,
            forward_commitments: forward_commitments,
            fhfb_id: member_position_hash['FHFB_ID'],
            cqr_rating: member_position_hash['CQR_RATING'],
            reporting_agency: member_position_hash['REPORTING_AGENCY'],
            credit_analyst: member_position_hash['CREDIT_ANALYST'],
            rhfa: {
              total_lt: member_position_hash['LT_ADV_OS'].to_i,
              available: member_position_hash['RHFA_AVAILABLE_LIMIT'].to_i
            },
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
                remaining_market: member_position_hash['EXCESS_SBC_MARKET_VALUE'].to_i,
                aa: {
                  total: member_position_hash['SBC_BORR_CAP_AA'].to_i,
                  remaining: member_position_hash['EXCESS_SBC_BORR_CAP_AA'].to_i,
                  total_market: member_position_hash['SBC_MARKET_VALUE_AA'].to_i,
                  remaining_market: member_position_hash['EXCESS_SBC_MV_AA'].to_i
                },
                aaa: {
                  total: member_position_hash['SBC_BORR_CAP_AAA'].to_i,
                  remaining: member_position_hash['EXCESS_SBC_BORR_CAP_AAA'].to_i,
                  total_market: member_position_hash['SBC_MARKET_VALUE_AAA'].to_i,
                  remaining_market: member_position_hash['EXCESS_SBC_MV_AAA'].to_i
                },
                agency: {
                  total: member_position_hash['SBC_BORR_CAP_AG'].to_i,
                  remaining: member_position_hash['EXCESS_SBC_BORR_CAP_AG'].to_i,
                  total_market: member_position_hash['SBC_MARKET_VALUE_AG'].to_i,
                  remaining_market: member_position_hash['EXCESS_SBC_MV_AG'].to_i
                }
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
              investments: member_position_hash['UNSECURED_CREDIT'].to_i,
              total_advances_outstanding: member_position_hash['REG_ADVANCES_OUTS'].to_i + member_position_hash['SBC_ADVANCES_OUTS'].to_i,
              total_credit_products_outstanding: member_position_hash['OTHER_CREDIT_PRODS'].to_i,
              total_advances_and_mpf: member_position_hash['ADVANCES_OUTS'].to_i + member_position_hash['MPF_CE_COLLATERAL_REQ'].to_i
            },
            capital_stock: capital_stock_and_leverage,
            advances: {
              end_of_prior_day: member_position_hash['ADVANCES_OUTS_EOD'].to_i,
              maturing_today_term: member_position_hash['ADVANCES_MAT_TODAY_TERM'].to_i,
              maturing_today_on: member_position_hash['ADVANCES_MAT_TODAY_ON'].to_i,
              scheduled_funding_today: member_position_hash['SCHEDULED_FUNDING_TODAY'].to_i,
              amortizing_adjustment: member_position_hash['ADVANCES_AMORTS'].to_i,
              partial_prepayment: member_position_hash['ADVANCES_PARTIAL_PREPAY'].to_i,
              funding_today: member_position_hash['AT_ADV_FUNDING'].to_i,
              repay_today: member_position_hash['ADVANCES_REPAYS'].to_i,
              mpf_intraday_activity: member_position_hash['MPF_ACTIVITY'].to_i,
              mpf_loan_balance: member_position_hash['MPF_UNPAID_BALANCE'].to_i,
              total_mpf: member_position_hash['TOTAL_MPF'].to_i,
              total_advances: member_position_hash['ADVANCES_OUTS'].to_i,
              total_advances_and_mpf: member_position_hash['ADVANCES_OUTS'].to_i + member_position_hash['MPF_ACTIVITY'].to_i + member_position_hash['MPF_UNPAID_BALANCE'].to_i
            }
          }
        end

        def self.member_details(app, logger, member_id)
          fhfa_number = nil
          sta_number = nil
          member_name = nil
          member_street = nil
          member_city = nil
          member_state = nil
          member_postal_code = nil

          member_name_query = <<-SQL
            SELECT web_adm.web_member_data.CP_ASSOC
            FROM web_adm.web_member_data
            WHERE web_adm.web_member_data.FHLB_ID = #{quote(member_id)}
          SQL

          sta_number_query = <<-SQL
            SELECT
            sta.sta_account_number
            FROM
            portfolios.sta sta,
            portfolios.sta_trans st
            where sta.fhlb_id = #{quote(member_id)}
            AND sta.sta_id = st.sta_id
            AND sta.sta_account_type = 1
            AND TRUNC(st.stx_update_date) = (SELECT TRUNC(MAX(stx_update_date))  FROM  portfolios.sta_trans)
          SQL

          customer_signature_card_sql = <<-SQL
            select
              cu_fhfb_id,
              needstwosigners
            from
              portfolios.customers cu
            left join
              signer.signaturecarddate s
            on
              cu.fhlb_id = s.fhlb_id
            where
              cu.fhlb_id = #{quote(member_id)}
          SQL

          address_sql = <<-SQL
            select
              shippingstreet,
              shippingcity,
              shippingstate,
              shippingpostalcode
            from
              crm.account acc
            left join
              portfolios.customers cu
            on
              cu.cu_fhfb_id = acc.fhfa_id__c
            WHERE
              cu.fhlb_id = #{quote(member_id)}
          SQL

          if app.settings.environment == :production
            member_name = ActiveRecord::Base.connection.execute(member_name_query).fetch.try(&:first)
            sta_number = ActiveRecord::Base.connection.execute(sta_number_query).fetch.try(&:first)
            customer_signature_card_data = ActiveRecord::Base.connection.execute(customer_signature_card_sql).fetch_hash
            if customer_signature_card_data
              fhfa_number = customer_signature_card_data['CU_FHFB_ID']
              dual_signers_required = (customer_signature_card_data['NEEDSTWOSIGNERS'].try(:to_i) == -1)
            end
            address_data = self.fetch_hash(logger, address_sql)
            if address_data
              member_street = address_data['SHIPPINGSTREET'].try(:read)
              member_city = address_data['SHIPPINGCITY']
              member_state = address_data['SHIPPINGSTATE']
              member_postal_code = address_data['SHIPPINGPOSTALCODE']
            end
            account_numbers = get_account_numbers(logger, member_id.to_i)
            member_pledged_account_number = account_numbers['P']
            member_unpledged_account_number = account_numbers['U']
          else
            member = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_details.json')))[member_id.to_s]
            if member
              member_name = member['name']
              fhfa_number = member['fhfa_number']
              sta_number = member['sta_number']
              dual_signers_required = member['dual_signers_required']
              member_street = member['street']
              member_city = member['city']
              member_state = member['state']
              member_postal_code = member['postal_code']
              member_pledged_account_number = member['pledged_account_number']
              member_unpledged_account_number = member['unpledged_account_number']
            end
          end

          return nil if member_name.nil?

          {
            name: member_name,
            fhfa_number: fhfa_number,
            sta_number: sta_number,
            dual_signers_required: dual_signers_required,
            street: member_street,
            city: member_city,
            state: member_state,
            postal_code: member_postal_code,
            pledged_account_number: member_pledged_account_number,
            unpledged_account_number: member_unpledged_account_number
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

          if app.settings.environment == :production
            # Collateral Asset Manager
            cam_query = <<-SQL
              select customer_master_id as fhlb_id, cs_user_id as username,  user_first_name || ' ' || user_last_name as full_name, email as email, user_first_name as first_name, user_last_name as last_name
              from fhlbown.customer_profile@colaprod_link p, fhlbown.v_cs_user_profile@colaprod_link c
              Where c.cs_user_id = p.collateral_analyst and customer_master_id = #{quote(member_id)}
            SQL
            cam = ActiveRecord::Base.connection.execute(cam_query).fetch_hash || {}

            # Relationship Manager
            rm_query = <<-SQL
              select c.fhlb_id, MR_FIRST || ' ' || MR_LAST as full_name, MR_PHONE as phone_number, MR_EMAIL as email, MR_FIRST as first_name, MR_LAST as last_name
              from PORTFOLIOS.CUSTOMERS C, PORTFOLIOS.MARKETING_REPS R
              where R.MR_INITIALS = C.CU_MARKETING_REP and fhlb_id = #{quote(member_id)}
            SQL
            rm = ActiveRecord::Base.connection.execute(rm_query).fetch_hash || {}
          else
            cam = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_contacts.json')))['cam']
            rm = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'member_contacts.json')))['rm']
          end

          rm[:email] = rm['email'] || rm['EMAIL']
          rm[:full_name] = rm['full_name'] || rm['FULL_NAME']
          if rm[:email] && (matches = rm[:email].match(/^(.+?)@/))
            rm[:username] = matches.captures.first.downcase
          end
          rm[:phone_number] = rm['phone_number'] || rm['PHONE_NUMBER']
          rm[:first_name] = rm['first_name'] || rm['FIRST_NAME']
          rm[:last_name] = rm['last_name'] || rm['LAST_NAME']

          cam[:email] = cam['email'] || cam['EMAIL']
          cam[:full_name] = cam['full_name'] || cam['FULL_NAME']
          cam[:username] = cam['username'] || cam['USERNAME']
          cam[:username] = cam[:username].downcase if cam[:username]
          cam[:first_name] = cam['first_name'] || cam['FIRST_NAME']
          cam[:last_name] = cam['last_name'] || cam['LAST_NAME']

          {
            cam: cam,
            rm: rm
          }.with_indifferent_access
        end

        def self.get_account_numbers_query(member_id)
          <<-SQL
            SELECT UPPER(SUBSTR(BAT.BAT_ACCOUNT_TYPE,1,1)) AS ACCOUNT_TYPE, ADX.ADX_ID
            FROM SAFEKEEPING.ACCOUNT_DOCKET_XREF ADX, SAFEKEEPING.BTC_ACCOUNT_TYPE BAT, SAFEKEEPING.CUSTOMER_PROFILE CP
            WHERE ADX.BAT_ID = BAT.BAT_ID
            AND ADX.CP_ID = CP.CP_ID
            AND CP.FHLB_ID = #{quote(member_id)}
            AND UPPER(SUBSTR(BAT.BAT_ACCOUNT_TYPE,1,1)) IN ('P', 'U')
            AND CONCAT(TRIM(TRANSLATE(ADX.ADX_BTC_ACCOUNT_NUMBER,' 0123456789',' ')), '*') = '*'
            AND (BAT.BAT_ACCOUNT_TYPE NOT LIKE '%DB%' AND BAT.BAT_ACCOUNT_TYPE NOT LIKE '%REIT%')
            ORDER BY TO_NUMBER(ADX.ADX_BTC_ACCOUNT_NUMBER) ASC
          SQL
        end

        def self.get_account_numbers(logger, member_id)
          account_numbers = {}
          fetch_hashes(logger, get_account_numbers_query(member_id)).each do |adx_ids_by_account_type|
            account_numbers[adx_ids_by_account_type["ACCOUNT_TYPE"]] = adx_ids_by_account_type["ADX_ID"]
          end
          account_numbers
        end
      end
    end
  end
end
