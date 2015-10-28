module MAPI
  module Services
    module Member
      module InterestRateResets
        def self.interest_rate_resets(app, member_id)
          if app.settings.environment == :production
            max_advances_update_date_query = <<-SQL
              SELECT max(as_of_date)+ 1 as max_advances_update_date
              FROM ods.position@ods_lk
            SQL
            max_advances_update_date_cursor = ActiveRecord::Base.connection.execute(max_advances_update_date_query)
            max_advances_update_row = max_advances_update_date_cursor.fetch()
            if max_advances_update_row
              max_advances_update_date = max_advances_update_row.first
            else
              return nil
            end

            max_advances_business_date_query = <<-SQL
              SELECT portfolios.cdb_utility.PRIOR_BUSINESS_DAY(#{ ActiveRecord::Base.connection.quote(max_advances_update_date)}) as max_advances_business_date
              FROM dual
            SQL
            max_advances_business_date_cursor = ActiveRecord::Base.connection.execute(max_advances_business_date_query)
            max_advances_business_date_row = max_advances_business_date_cursor.fetch()
            if max_advances_business_date_row
              max_advances_business_date = max_advances_business_date_row.first
            else
              return nil
            end

            advances_prior_business_date_query = <<-SQL
              SELECT portfolios.cdb_utility.PRIOR_BUSINESS_DAY(#{ ActiveRecord::Base.connection.quote(max_advances_business_date)}) as advances_prior_business_date
              FROM dual
            SQL
            advances_prior_business_date_cursor = ActiveRecord::Base.connection.execute(advances_prior_business_date_query)
            advances_prior_business_date_row = advances_prior_business_date_cursor.fetch()
            if advances_prior_business_date_row
              advances_prior_business_date = advances_prior_business_date_row.first
            else
              return nil
            end

            interest_rate_reset_query = <<-SQL
            SELECT ADX_UPDATE_DATE, FHLB_ID, ADV_ADVANCE_NUMBER as TRANSACTION_NUMBER,
              MATURITY_DATE as ADV_MATURITY_DATE, CURRENT_COUPON as INTEREST_RATE,
              ADX_REPRICING_DATE as NEXT_RESET_DATE, PRIOR_ADX_COUPON as PRIOR_RATE,
              PRIOR_REPRICING_DATE, PRIOR_ADX_UPDATE_DATE, isOpenMaturity as IS_OPEN_MATURITY, SCID, ISSUE_NUMBER
            FROM web_inet.web_advances_int_rate_base_v adx,
              (SELECT SCID as p_scid, current_coupon as PRIOR_ADX_COUPON,
              adx_repricing_date as PRIOR_REPRICING_DATE, adx_update_date as PRIOR_ADX_UPDATE_DATE
              FROM web_inet.web_advances_int_rate_base_v
              WHERE FHLB_ID =#{ ActiveRecord::Base.connection.quote(member_id)} AND
              adx_update_date = #{ ActiveRecord::Base.connection.quote(advances_prior_business_date)}) prioradx
            WHERE
            FHLB_ID = #{ ActiveRecord::Base.connection.quote(member_id)} AND
            ADX.ADV_INDEX IS NOT NULL AND ADX.scid  = p_scid  AND ADX.ADX_UPDATE_DATE = #{ ActiveRecord::Base.connection.quote(max_advances_business_date)}
            AND ((ADX.current_coupon <>  PRIOR_ADX_COUPON) OR (TRUNC(PRIOR_REPRICING_DATE) = TRUNC(ADX.ADX_UPDATE_DATE)) OR (ADX.isOpenMaturity = 'true'))
            ORDER BY ADV_ADVANCE_NUMBER
            SQL

            interest_rate_reset_cursor = ActiveRecord::Base.connection.execute(interest_rate_reset_query)
            interest_rate_resets = []
            while row = interest_rate_reset_cursor.fetch_hash()
              interest_rate_resets << row.with_indifferent_access
            end
            date_processed = max_advances_business_date
          else
            date_processed = MAPI::Services::Member::CashProjections::Private.fake_as_of_date
            interest_rate_resets = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'interest_rate_resets.json')))
            interest_rate_resets = interest_rate_resets.collect{ |reset| reset.with_indifferent_access }
          end

          {
            date_processed: (date_processed.to_date if date_processed),
            interest_rate_resets: Private.format_interest_rate_resets(interest_rate_resets)
          }
        end

        module Private
          def self.format_interest_rate_resets(advances)
            advances.collect do |advance|
              next_reset = advance[:IS_OPEN_MATURITY].to_s == 'true' ? nil : advance[:NEXT_RESET_DATE].to_date
              {
                effective_date: (advance[:ADX_UPDATE_DATE].to_date if advance[:ADX_UPDATE_DATE]),
                advance_number: (advance[:TRANSACTION_NUMBER].to_s if advance[:TRANSACTION_NUMBER]),
                prior_rate: (advance[:PRIOR_RATE].to_f if advance[:PRIOR_RATE]),
                new_rate: (advance[:INTEREST_RATE].to_f if advance[:INTEREST_RATE]),
                next_reset: next_reset
              }
            end
          end
        end
      end
    end
  end
end
