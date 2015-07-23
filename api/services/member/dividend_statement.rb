module MAPI
  module Services
    module Member
      module DividendStatement
        def self.dividend_statement(app, member_id, date)
          member_id = member_id.to_i

          # TODO rig up `date` param to query after design figures out how we will be inputting this.  It might end up being `div_id` instead of date.
          if app.settings.environment == :production

            # TODO replace this with the real mechanism for grabbing a dividend statement once it's designed.  For now, we'll just show the latest
            # div_id based on date_end.  '1-Jan-2013' is hardcoded in to reduce scope of query and has no special significance
            div_id_query = <<-SQL
              SELECT div_id, date_end, date_paid
              FROM capstock.capstock_div_fhlb
              WHERE date_end >= '1-Jan-2013' ORDER BY DATE_PAID DESC
            SQL

            div_id_cursor = ActiveRecord::Base.connection.execute(div_id_query)
            div_id_row = div_id_cursor.fetch()
            if div_id_row
              div_id = div_id_row.first
            else
              return nil
            end

            quoted_member_id = ActiveRecord::Base.connection.quote(member_id)
            quoted_div_id = ActiveRecord::Base.connection.quote(div_id)
            
            # Need to use this to get STA account number instead of MAPI::Services::Member::Profile.member_details(app, member_id)[:sta_number],
            # as the STA account associated with historic dividends may be different than the one returned by the profile endpoint
            sta_account_number_query = <<-SQL
              select sta_account_number, max(f.trans_date) last_used_date, e.FHLB_ID, 1 as order_seq
              From portfolios.sta  e, portfolios.sta_web_detail   f
              Where e.sta_account_type = 1 and  e.fhlb_id = f.fhlb_id
              and e.fhlb_id =  #{quoted_member_id}
              and f.fhlb_id = #{quoted_member_id}
              and f.trans_date =
                (
                  select max(tran_date)from capstock.capstock_tran
                  where div_id =  #{quoted_div_id}
                  and trans_type = 'D'
                  and fhlb_id = #{quoted_member_id}
                )
              group by e.fhlb_id, sta_account_number
              union  -- this is for just in case STA was credited earlier due to non-business day)
              select sta_account_number, max(f.trans_date) last_used_date, e.FHLB_ID, 2 as order_seq
              From portfolios.sta  e, portfolios.sta_web_detail   f
              Where e.sta_account_type = 1 and  e.fhlb_id = f.fhlb_id
              and e.fhlb_id =  #{quoted_member_id}
              and f.fhlb_id =  #{quoted_member_id}
              and f.trans_date >= (
                select portfolios.cdb_utility.PRIOR_BUSINESS_DAY(max(tran_date))
                from capstock.capstock_tran
                  where div_id = #{quoted_div_id}
                  and trans_type = 'D'
                  and fhlb_id = #{quoted_member_id}
                )
              group by e.fhlb_id, sta_account_number order by order_seq, last_used_date
            SQL

            sta_account_number_cursor = ActiveRecord::Base.connection.execute(sta_account_number_query)
            sta_account_number_row = sta_account_number_cursor.fetch()
            sta_account_number = sta_account_number_row.first if sta_account_number_row

            dividend_summary_query = <<-SQL
              SELECT h.fhlb_id, h.div_id as div_id, tran_date, div_rate, total_div_hist, avg_shr_os, no_share, no_share_par_value,
                cash_dividend, total_div_tran, QYear, Qtr, div_per_shr, annual_div_rate
              FROM
                (SELECT DIV_ID, max(DIV_RATE) div_rate , FHLB_ID, sum(dividend) total_div_hist, sum(avg_shr_os) avg_shr_os
                FROM CAPSTOCK.CAPSTOCK_DIV_FHLB_HIST b
                WHERE fhlb_id = #{quoted_member_id}
                AND div_id = #{quoted_div_id}
                GROUP BY div_id, fhlb_id) h,
                (SELECT a.fhlb_id, a.div_id, max(tran_id) tran_id, max(tran_date) tran_date, max(par_value) par_value, max(class) class,
                  sum(no_share) no_share, sum(no_share * par_value) as no_share_par_value, sum(cash_dividend) cash_dividend,
                  sum(no_share * par_value) + sum(cash_dividend) as total_div_tran,  substr(a.div_id, 1,4) as QYear, substr(a.div_id, 5,2) as Qtr,
                  max(c.div_per_shr) as div_per_shr,
                  max(c.annual_div_rate) as annual_div_rate
                FROM capstock.capstock_tran a , capstock.capstock_div_fhlb c
                WHERE trans_type = 'D'
                  AND a.fhlb_id = #{quoted_member_id}
                  AND a.div_id = #{quoted_div_id}
                  AND a.div_id = c.div_id
                GROUP BY a.trans_type, a.fhlb_id, a.div_id) x
              WHERE h.fhlb_id = x.fhlb_id And h.div_id = x.div_id
            SQL

            dividend_summary_cursor = ActiveRecord::Base.connection.execute(dividend_summary_query)
            dividend_summary = dividend_summary_cursor.fetch_hash() || {}
            dividend_summary = dividend_summary.with_indifferent_access

            dividend_details_query = <<-SQL
              SELECT cert_id, issue_date, eff_from, eff_to, no_share_holding, eff_days, nvl(avg_shr_os, 0.00)  avg_shr_os_par_value,
                nvl(dividend, 0) dividend
              FROM CAPSTOCK.CAPSTOCK_DIV_FHLB_HIST b
              WHERE fhlb_id =  #{quoted_member_id}
              AND div_id = #{quoted_div_id}
              ORDER BY issue_date
            SQL

            dividend_details_cursor = ActiveRecord::Base.connection.execute(dividend_details_query)

            dividend_details = []
            while row = dividend_details_cursor.fetch_hash()
              dividend_details << row.with_indifferent_access
            end
          else
            dividend_summary = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'dividend_summary_data.json'))).with_indifferent_access
            dividend_summary[:TRAN_DATE] = MAPI::Services::Member::CashProjections::Private.fake_as_of_date # TODO change this to reflect whatever mechanism we will use for historic dividend statements
            dividend_details = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'dividend_details.json')))
            dividend_details = dividend_details.collect{ |x| x.with_indifferent_access}
            sta_account_number = '25100033'
          end

          {
            transaction_date: (dividend_summary[:TRAN_DATE].to_date if dividend_summary[:TRAN_DATE]),
            annualized_rate: (dividend_summary[:ANNUAL_DIV_RATE].to_f if dividend_summary[:ANNUAL_DIV_RATE]),
            rate: (dividend_summary[:DIV_PER_SHR].to_f if dividend_summary[:DIV_PER_SHR]),
            average_shares_outstanding: ((dividend_summary[:AVG_SHR_OS] / 100.0).to_f if dividend_summary[:AVG_SHR_OS]),
            shares_dividend: (dividend_summary[:NO_SHARE].to_i if dividend_summary[:NO_SHARE]),
            shares_par_value: (dividend_summary[:NO_SHARE_PAR_VALUE].to_f if dividend_summary[:NO_SHARE_PAR_VALUE]),
            cash_dividend: (dividend_summary[:CASH_DIVIDEND].to_f if dividend_summary[:CASH_DIVIDEND]),
            total_dividend: (dividend_summary[:TOTAL_DIV_TRAN].to_f if dividend_summary[:TOTAL_DIV_TRAN]),
            sta_account_number: (sta_account_number.to_s if sta_account_number),
            details: Private.format_dividend_details(dividend_details)
          }
        end

        # private
        module Private
          def self.format_dividend_details(dividends)
            dividends.collect do |dividend|
              {
                issue_date: (dividend[:ISSUE_DATE].to_date if dividend[:ISSUE_DATE]),
                certificate_sequence: (dividend[:CERT_ID].to_s if dividend[:CERT_ID]),
                start_date: (dividend[:EFF_FROM].to_date if [:EFF_FROM]),
                end_date: (dividend[:EFF_TO].to_date if dividend[:EFF_TO]),
                shares_outstanding: (dividend[:NO_SHARE_HOLDING].to_i if dividend[:NO_SHARE_HOLDING]),
                average_shares_outstanding: ((dividend[:AVG_SHR_OS_PAR_VALUE] / 100.0).to_f if dividend[:AVG_SHR_OS_PAR_VALUE]),
                dividend: (dividend[:DIVIDEND].to_f if dividend[:DIVIDEND]),
                days_outstanding: (dividend[:EFF_DAYS].to_i if dividend[:EFF_DAYS])
              }
            end
          end
        end
      end
    end
  end
end
