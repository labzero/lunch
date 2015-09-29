module MAPI
  module Services
    module Member
      module DividendStatement
        def self.dividend_statement(env, member_id, start_date, div_id)
          member_id = member_id.to_i

          # get div_ids
          if env == :production
            div_id_query = <<-SQL
              SELECT div_id, date_end, date_paid
              FROM capstock.capstock_div_fhlb
              WHERE date_end >= #{ ActiveRecord::Base.connection.quote(start_date)} ORDER BY DATE_PAID DESC
            SQL

            div_ids = []
            div_id_cursor = ActiveRecord::Base.connection.execute(div_id_query)
            while row = div_id_cursor.fetch_hash()
              div_ids.push(row['DIV_ID'])
            end
          else
            div_ids = Private.fake_div_ids(start_date)
          end
          div_id = div_ids.first if div_id == 'current'

          r = Random.new(div_id[0..3].to_i * div_id.last.to_i) unless env == :production # used in the creation of fake data for development

          # get STA number
          if env == :production
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
          else
            sta_account_number_row = [r.rand(10000000..99999999).to_s]
          end
          sta_account_number = sta_account_number_row.first if sta_account_number_row

          # get dividend_summary
          if env == :production
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
          else
            dividend_summary = Private.fake_div_summary(div_id, r)
          end
            dividend_summary = dividend_summary.with_indifferent_access

          # get dividend_details
          if env == :production
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
            dividend_details = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'dividend_details.json')))[r.rand(0..2)]
            dividend_details.each_index do |i|
              dividend_details[i]['EFF_FROM'] = Private.start_date_from_div_id(div_id)
              dividend_details[i]['EFF_TO'] = Private.end_date_from_div_id(div_id)
            end

          end
          dividend_details = dividend_details.collect{ |x| x.with_indifferent_access}

          {
            div_ids: div_ids,
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

          def self.fake_div_ids(start_date)
            div_ids = []
            (start_date..last_quarter_end_date).each do |date|
              quarter = (date.month / 3.0).ceil
              div_id = "#{date.year}Q#{quarter}"
              div_ids.push(div_id) unless div_ids.include?(div_id)
            end
            div_ids.reverse
          end

          def self.last_quarter_end_date
            today = Time.zone.today
            last_quarter = (today.month / 3.0).ceil - 1
            Time.zone.parse(
              case last_quarter
              when 0
                "#{today.year - 1}-12-31"
              when 1
                "#{today.year}-3-31"
              when 2
                "#{today.year}-6-30"
              when 3
                "#{today.year}-9-30"
              end
            ).to_date
          end

          def self.fake_div_summary(div_id, r)
            cash_dividend = r.rand(111111..999999) + r.rand().round(2)
            {
              "TRAN_DATE" => end_date_from_div_id(div_id),
              "DIV_RATE" => (1 + r.rand().round(2)),
              "ANNUAL_DIV_RATE" => (r.rand(3..6) + r.rand().round(2)),
              "DIV_PER_SHR" => (1 + r.rand().round(2)),
              "AVG_SHR_OS" => r.rand(11111111..99999999),
              "NO_SHARE" => 0,
              "NO_SHARE_PAR_VALUE" => 0,
              "CASH_DIVIDEND" => cash_dividend,
              "TOTAL_DIV_TRAN" => cash_dividend
            }
          end

          def self.start_date_from_div_id(div_id)
            year = div_id[0..3]
            case div_id.last.to_i
              when 1
                "#{year}-1-1"
              when 2
                "#{year}-4-1"
              when 3
                "#{year}-7-1"
              when 4
                "#{year}-10-1"
            end
          end

          def self.end_date_from_div_id(div_id)
            year = div_id[0..3]
            case div_id.last.to_i
              when 1
                "#{year}-3-31"
              when 2
                "#{year}-6-30"
              when 3
                "#{year}-9-30"
              when 4
                "#{year}-12-31"
            end
          end

        end
      end
    end
  end
end
