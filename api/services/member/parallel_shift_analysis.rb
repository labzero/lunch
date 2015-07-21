module MAPI
  module Services
    module Member
      module ParallelShiftAnalysis
        def self.parallel_shift(app, member_id)
          member_id = member_id.to_i

          if app.settings.environment == :production
            max_date_query = <<-SQL
              SELECT MAX(AS_OF_DATE) MAX_VAL_DATE
              FROM HARMDM.VALUATIONS, ODS.DEAL@ODS_LK d
              WHERE deal_number = dealno AND d.instrument = 'ADVS' AND option_code = 'PUT' AND shock_bps <> 0
            SQL

            max_date_cursor = ActiveRecord::Base.connection.execute(max_date_query)
            max_date_row = max_date_cursor.fetch()
            if max_date_row
              max_date = max_date_row.first
            else
              return nil
            end

            parallel_shift_query = <<-SQL
              SELECT V.AS_OF_DATE Valuation_As_Of_Date, v.DEALNO, D.Deal_ID,
                DL.Deal_Leg_ID, P.Position_ID, P.AS_OF_DATE Position_As_Of_Date,
                P.Current_Coupon, V.PRICE, V.SHOCK_BPS, D.ISSUE_DATE, D.FHLB_ID
              FROM harmdm.valuations V,
              ods.deal@ODS_LK D,
              ods.deal_leg@ODS_LK DL,
              ods.position@ODS_LK P
              WHERE V.DealNo = D.Deal_Number
              AND D.FHLB_ID =  #{ActiveRecord::Base.connection.quote(member_id)}
              AND D.Deal_ID = DL.Deal_ID AND DL.Deal_Leg_ID = P.Deal_Leg_ID
              AND D.instrument = 'ADVS' AND D.option_code = 'PUT'
              AND v.dual_curve_override = 'N' AND v.as_of_date = #{ ActiveRecord::Base.connection.quote(max_date)} AND p.as_of_date =  (select max(P2.as_of_date) from ods.position@ODS_LK P2 WHERE P2.Deal_Leg_ID = P.Deal_Leg_ID)
              ORDER BY D.Issue_Date Asc, V.DealNo Asc, v.shock_bps Asc
            SQL

            parallel_shift_cursor = ActiveRecord::Base.connection.execute(parallel_shift_query)

            parallel_shift_data = []
            while row = parallel_shift_cursor.fetch_hash()
              parallel_shift_data << row.with_indifferent_access
            end
          else
            max_date = MAPI::Services::Member::CashProjections::Private.fake_as_of_date
            parallel_shift_data = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'parallel_shift_data.json')))
            parallel_shift_data = parallel_shift_data.collect{ |advance| advance.with_indifferent_access }
          end

          {
            as_of_date: (max_date.to_date if max_date),
            putable_advances: Private.format_parallel_shift_data(parallel_shift_data)
          }
        end

        # private
        module Private
          def self.format_parallel_shift_data(parallel_shift_data)
            putable_advances = []
            advances_by_account_number = parallel_shift_data.group_by{|x| x[:DEALNO]}
            advances_by_account_number.each do |advance_number, advance_group|
              putable_advance = {shift_neg_300: nil, shift_neg_200: nil, shift_neg_100: nil, shift_0: nil, shift_100: nil, shift_200: nil, shift_300: nil}
              putable_advance[:advance_number] = advance_number.to_s
              putable_advance[:issue_date] = advance_group.first[:ISSUE_DATE].to_date if advance_group.first && advance_group.first[:ISSUE_DATE]
              putable_advance[:interest_rate] = advance_group.first[:CURRENT_COUPON].to_f if advance_group.first && advance_group.first[:CURRENT_COUPON]
              advance_group.each do |row|
                shock_bps = row[:SHOCK_BPS].to_i
                case shock_bps
                  when -300
                    putable_advance[:shift_neg_300] = row[:PRICE].to_f if row[:PRICE]
                  when -200
                    putable_advance[:shift_neg_200] = row[:PRICE].to_f if row[:PRICE]
                  when -100
                    putable_advance[:shift_neg_100] = row[:PRICE].to_f if row[:PRICE]
                  when 0
                    putable_advance[:shift_0] = row[:PRICE].to_f if row[:PRICE]
                  when 100
                    putable_advance[:shift_100] = row[:PRICE].to_f if row[:PRICE]
                  when 200
                    putable_advance[:shift_200] = row[:PRICE].to_f if row[:PRICE]
                  when 300
                    putable_advance[:shift_300] = row[:PRICE].to_f if row[:PRICE]
                end
              end
              putable_advances << putable_advance
            end
            putable_advances
          end
        end
      end
    end
  end
end
