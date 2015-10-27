module MAPI
  module Services
    module Member
      module BorrowingCapacity
        # borrowing capacity details
        def self.borrowing_capacity_details(app, member_id, as_of_date )
          member_id = member_id.to_i

          # ASSUMPTION is always get current position.  The Date param is for future use when allow historical data
          bc_balances_connection_string = <<-SQL
          SELECT UPDATE_DATE, STD_EXCL_BL_BC, STD_EXCL_BANK_BC, STD_EXCL_REG_BC, STD_SECURITIES_BC, STD_ADVANCES, STD_LETTERS_CDT_USED,
          STD_SWAP_COLL_REQ, STD_COVER_OTHER_PT_DEF, STD_PREPAY_FEES, STD_OTHER_COLL_REQ, STD_MPF_CE_COLL_REQ, STD_COLL_EXCESS_DEF,
          SBC_MV_AA, SBC_BC_AA, SBC_ADVANCES_AA, SBC_COVER_OTHER_AA, SBC_MV_COLL_EXCESS_DEF_AA, SBC_COLL_EXCESS_DEF_AA,
          SBC_MV_AAA, SBC_BC_AAA, SBC_ADVANCES_AAA, SBC_COVER_OTHER_AAA, SBC_MV_COLL_EXCESS_DEF_AAA, SBC_COLL_EXCESS_DEF_AAA,
          SBC_MV_AG, SBC_BC_AG, SBC_ADVANCES_AG, SBC_COVER_OTHER_AG, SBC_MV_COLL_EXCESS_DEF_AG, SBC_COLL_EXCESS_DEF_AG,
          SBC_OTHER_COLL_REQ, SBC_COLL_EXCESS_DEF, STD_TOTAL_BC, SBC_BC, SBC_MV, SBC_ADVANCES, SBC_MV_COLL_EXCESS_DEF
          FROM V_CONFIRM_SUMMARY_INTRADAY@COLAPROD_LINK.WORLD
          WHERE FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)}
          SQL

          bc_std_breakdown_string = <<-SQL
          SELECT COLLATERAL_TYPE, STD_COUNT, STD_UNPAID_BALANCE, STD_BORROWING_CAPACITY,
          STD_ORIGINAL_AMOUNT, STD_MARKET_VALUE, COLLATERAL_SORT_ID
          FROM V_CONFIRM_DETAIL@COLAPROD_LINK.WORLD
          WHERE FHLB_ID = #{ActiveRecord::Base.connection.quote(member_id)}
          ORDER BY COLLATERAL_SORT_ID
          SQL

          # set the expected balances value to 0 just in case it is not found, want to return 0 values
          balance_hash = {}
          std_breakdown= []
          if app.settings.environment == :production
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
          # format the SBC into an array of hash
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

          {  date: as_of_date.to_date,
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