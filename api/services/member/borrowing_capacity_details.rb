module MAPI
  module Services
    module Member
      module BorrowingCapacity
        include MAPI::Shared::Utils

        def self.borrowing_capacity_data_available?(app, member_id, as_of_date=Time.zone.now.to_s)
          member_id = member_id.to_i
          as_of_date = Date.parse(as_of_date)

          data_available_sql = <<-SQL
          SELECT PERIODVALUE
          FROM FHLBOWN.COLLATERAL_SUMMARY_TYPE_HIST@COLAPROD_LINK.WORLD
          WHERE CUSTOMER_MASTER_ID = #{quote(member_id)}
          AND PERIODVALUE = #{quote(as_of_date.strftime('%Y%m'))}
          SQL

          data_for_period = unless should_fake?(app)
            fetch_hash(app.logger, data_available_sql)['PERIODVALUE']
          else
            member = fake('borrowing_capacity_data_available')[member_id.to_s]
            if member
              date = member[as_of_date.strftime('%Y%m')] 
              if date
                date['PERIODVALUE']
              else
                nil
              end
            else
              nil
            end
          end      
          { data_available: !data_for_period.nil? }
        end

        def self.borrowing_capacity_details(app, member_id, as_of_date)
          member_id = member_id.to_i
          as_of_date = Date.parse(as_of_date)

          if as_of_date.year == Time.zone.today.year && as_of_date.month == Time.zone.today.month
            bc_balances_connection_string = <<-SQL
            SELECT UPDATE_DATE, STD_EXCL_BL_BC, STD_EXCL_BANK_BC, STD_EXCL_REG_BC, STD_SECURITIES_BC, STD_ADVANCES, STD_LETTERS_CDT_USED,
            STD_SWAP_COLL_REQ, STD_COVER_OTHER_PT_DEF, STD_PREPAY_FEES, STD_OTHER_COLL_REQ, STD_MPF_CE_COLL_REQ, STD_COLL_EXCESS_DEF,
            SBC_MV_AA, SBC_BC_AA, SBC_ADVANCES_AA, SBC_COVER_OTHER_AA, SBC_MV_COLL_EXCESS_DEF_AA, SBC_COLL_EXCESS_DEF_AA,
            SBC_MV_AAA, SBC_BC_AAA, SBC_ADVANCES_AAA, SBC_COVER_OTHER_AAA, SBC_MV_COLL_EXCESS_DEF_AAA, SBC_COLL_EXCESS_DEF_AAA,
            SBC_MV_AG, SBC_BC_AG, SBC_ADVANCES_AG, SBC_COVER_OTHER_AG, SBC_MV_COLL_EXCESS_DEF_AG, SBC_COLL_EXCESS_DEF_AG,
            SBC_OTHER_COLL_REQ, SBC_COLL_EXCESS_DEF, STD_TOTAL_BC, SBC_BC, SBC_MV, SBC_ADVANCES, SBC_MV_COLL_EXCESS_DEF
            FROM V_CONFIRM_SUMMARY_INTRADAY@COLAPROD_LINK.WORLD
            WHERE FHLB_ID = #{quote(member_id)}
            SQL

            bc_std_breakdown_string = <<-SQL
            SELECT COLLATERAL_TYPE, STD_COUNT, STD_UNPAID_BALANCE, STD_BORROWING_CAPACITY,
            STD_ORIGINAL_AMOUNT, STD_MARKET_VALUE, COLLATERAL_SORT_ID
            FROM V_CONFIRM_DETAIL@COLAPROD_LINK.WORLD
            WHERE FHLB_ID = #{quote(member_id)}
            ORDER BY COLLATERAL_SORT_ID
            SQL
          else
            bc_balances_connection_string = <<-SQL
            SELECT CUSTOMER_MASTER_ID, STD_EXCL_BL_BC, STD_EXCL_BANK_BC, STD_EXCL_REG_BC, STD_SECURITIES_BC, STD_ADVANCES, STD_LETTERS_CDT_USED,
            STD_SWAP_COLL_REQ, STD_COVER_OTHER_PT_DEF, STD_PREPAY_FEES, STD_OTHER_COLL_REQ, STD_MPF_CE_COLL_REQ, STD_COLL_EXCESS_DEF,
            SBC_MV_AA, SBC_BC_AA, SBC_ADVANCES_AA, SBC_COVER_OTHER_AA, SBC_MV_COLL_EXCESS_DEF_AA, SBC_COLL_EXCESS_DEF_AA,
            SBC_MV_AAA, SBC_BC_AAA, SBC_ADVANCES_AAA, SBC_COVER_OTHER_AAA, SBC_MV_COLL_EXCESS_DEF_AAA, SBC_COLL_EXCESS_DEF_AAA,
            SBC_MV_AG, SBC_BC_AG, SBC_ADVANCES_AG, SBC_COVER_OTHER_AG, SBC_MV_COLL_EXCESS_DEF_AG, SBC_COLL_EXCESS_DEF_AG,
            SBC_OTHER_COLL_REQ, SBC_COLL_EXCESS_DEF, STD_TOTAL_BC, SBC_BC, SBC_MV, SBC_ADVANCES, SBC_MV_COLL_EXCESS_DEF
            FROM FHLBOWN.COLLATERAL_SUMMARY_TYPE_HIST@COLAPROD_LINK.WORLD
            WHERE CUSTOMER_MASTER_ID = #{quote(member_id)}
            AND PERIODVALUE = #{quote(as_of_date.strftime('%Y%m'))}
            SQL

            bc_std_breakdown_string = <<-SQL
            SELECT COLLATERAL_TYPE, STD_COUNT, STD_UNPAID_BALANCE, STD_BORROWING_CAPACITY, STD_ORIGINAL_AMOUNT, STD_MARKET_VALUE, COLLATERAL_SORT_ID
            FROM FHLBOWN.COLLATERAL_SUMMARY_TYPE_HIST@COLAPROD_LINK.WORLD
            WHERE CUSTOMER_MASTER_ID = #{quote(member_id)}
            AND PERIODVALUE = #{quote(as_of_date.strftime('%Y%m'))}
            ORDER BY COLLATERAL_SORT_ID
            SQL
          end

          balance_hash = {}
          std_breakdown= []
          unless should_fake?(app)
            bc_balances_cursor = ActiveRecord::Base.connection.execute(bc_balances_connection_string)
            while row = bc_balances_cursor.fetch_hash()
              balance_hash = row
              break
            end
            bc_std_breakdown_cursor = ActiveRecord::Base.connection.execute(bc_std_breakdown_string)
            while row = bc_std_breakdown_cursor.fetch_hash()
              std_breakdown.push(row)
            end
          else
            balance_hash = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'borrowing_capacity_balances.json')))
            std_breakdown = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'borrowing_capacity_std_breakdown.json')))
          end
          standard_breakdown_formatted = []

          std_breakdown.each do |row|
            reformat_hash = {'type' => row['COLLATERAL_TYPE'],
                             'count' => (row['STD_COUNT'] || 0).round,
                             'original_amount' => (row['STD_ORIGINAL_AMOUNT'] || 0).to_f.round,
                             'unpaid_principal' => (row['STD_UNPAID_BALANCE'] || 0).to_f.round,
                             'market_value' => (row['STD_MARKET_VALUE'] || 0).to_f.round,
                             'borrowing_capacity' => (row['STD_BORROWING_CAPACITY'] || 0).to_f.round
            }
            standard_breakdown_formatted.push(reformat_hash)
          end

          sbc_breakdown = {
              aa:
              { total_market_value: (balance_hash['SBC_MV_AA'] || 0).to_f.round,
                total_borrowing_capacity: (balance_hash['SBC_BC_AA'] || 0).to_f.round,
                advances: (balance_hash['SBC_ADVANCES_AA'] || 0).to_f.round,
                standard_credit: (balance_hash['SBC_COVER_OTHER_AA'] || 0).to_f.round,
                remaining_market_value: (balance_hash['SBC_MV_COLL_EXCESS_DEF_AA'] || 0).to_f.round,
                remaining_borrowing_capacity: (balance_hash['SBC_COLL_EXCESS_DEF_AA'] || 0).to_f.round
              },
              aaa:
              { total_market_value: (balance_hash['SBC_MV_AAA'] || 0).to_f.round,
                total_borrowing_capacity: (balance_hash['SBC_BC_AAA'] || 0).to_f.round,
                advances: (balance_hash['SBC_ADVANCES_AAA'] || 0).to_f.round,
                standard_credit: (balance_hash['SBC_COVER_OTHER_AAA'] || 0).to_f.round,
                remaining_market_value: (balance_hash['SBC_MV_COLL_EXCESS_DEF_AAA'] || 0).to_f.round,
                remaining_borrowing_capacity: (balance_hash['SBC_COLL_EXCESS_DEF_AAA'] || 0).to_f.round
              },
              agency:
              { total_market_value: (balance_hash['SBC_MV_AG'] || 0).to_f.round,
                total_borrowing_capacity: (balance_hash['SBC_BC_AG'] || 0).to_f.round,
                advances: (balance_hash['SBC_ADVANCES_AG'] || 0).to_f.round,
                standard_credit: (balance_hash['SBC_COVER_OTHER_AG'] || 0).to_f.round,
                remaining_market_value: (balance_hash['SBC_MV_COLL_EXCESS_DEF_AG'] || 0).to_f.round,
                remaining_borrowing_capacity: (balance_hash['SBC_COLL_EXCESS_DEF_AG'] || 0).to_f.round
              }
          }

          {  date: as_of_date,
             standard: {
                 collateral: standard_breakdown_formatted,
                 securities: (balance_hash['STD_SECURITIES_BC'] || 0).to_f.round,
                 excluded: {
                     blanket_lien: (balance_hash['STD_EXCL_BL_BC'] || 0).to_f.round,
                     bank: (balance_hash['STD_EXCL_BANK_BC'] || 0).to_f.round,
                     regulatory: (balance_hash['STD_EXCL_REG_BC'] || 0).to_f.round
                 },
                 utilized: {
                     advances: (balance_hash['STD_ADVANCES'] || 0).to_f.round,
                     letters_of_credit: (balance_hash['STD_LETTERS_CDT_USED'] || 0).to_f.round,
                     swap_collateral: (balance_hash['STD_SWAP_COLL_REQ'] || 0).to_f.round,
                     sbc_type_deficiencies: (balance_hash['STD_COVER_OTHER_PT_DEF'] || 0).to_f.round,
                     payment_fees: (balance_hash['STD_PREPAY_FEES'] || 0).to_f.round,
                     other_collateral: (balance_hash['STD_OTHER_COLL_REQ'] || 0).to_f.round,
                     mpf_ce_collateral: (balance_hash['STD_MPF_CE_COLL_REQ'] || 0).to_f.round
                 }
             },
             sbc: {
                 collateral: sbc_breakdown,
                 utilized: {
                     other_collateral: (balance_hash['SBC_OTHER_COLL_REQ'] || 0).to_f.round,
                     excluded_regulatory: 0   # no matching data column in database
                 }
             }
          }.to_json
        end
      end
    end
  end
end