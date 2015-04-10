module MAPI
  module Services
    module Member
      module CashProjections
        def self.cash_projections(app, member_id)
          member_id = member_id.to_i

          if app.settings.environment == :production

            # get the last date for which FHLB calculated Cash Projections, independent of individual member banks
            most_recent_cash_projection_date_query = <<-SQL
              SELECT MAX(CPJ_BTC_DATE) FROM SAFEKEEPING.CASH_PROJECTIONS
            SQL
            as_of_date_cursor = ActiveRecord::Base.connection.execute(most_recent_cash_projection_date_query)
            while row = as_of_date_cursor.fetch()
              as_of_date = row.first
              break
            end
            # get cash projections using as_of_date from above.  May be blank for this particular member if they had no cash projections as of this date.
            cash_projections_query = <<-SQL
              SELECT  CPJ_SETTLE_DATE, CPJ_BTC_ACCOUNT_NUMBER, CPJ_CUSIP, CPJ_DESC_LINE_1, CPJ_TRANS_CODE, CPJ_UNITS, CPJ_POOL_ID, CPJ_ISSUE_RATE, CPJ_MATURITY_DATE, CPJ_PRINCIPAL_AMOUNT, CPJ_INTEREST_AMOUNT, CPJ_TOTAL_AMOUNT
              FROM SAFEKEEPING.ACCOUNT_DOCKET_XREF, SAFEKEEPING.CUSTOMER_PROFILE, SAFEKEEPING.CASH_PROJECTIONS
              WHERE RTRIM(CPJ_BTC_ACCOUNT_NUMBER) = RTRIM(ADX_BTC_ACCOUNT_NUMBER)
              AND CUSTOMER_PROFILE.CP_ID = ACCOUNT_DOCKET_XREF.CP_ID
              AND CASH_PROJECTIONS.CPJ_BTC_DATE = #{ ActiveRecord::Base.connection.quote(as_of_date)}
              AND CUSTOMER_PROFILE.FHLB_ID = #{ ActiveRecord::Base.connection.quote(member_id)}
            SQL
            cash_projections_cursor = ActiveRecord::Base.connection.execute(cash_projections_query)
            projections = []
            while row = cash_projections_cursor.fetch_hash()
              projections << row.with_indifferent_access
            end
          else
            as_of_date = Private.fake_as_of_date
            projections = Private.fake_cash_projections(as_of_date)
          end

          total_net_amount = projections.inject(0) {|sum, projection| sum + projection[:CPJ_TOTAL_AMOUNT].to_f}
          total_principal = projections.inject(0) {|sum, projection| sum + projection[:CPJ_PRINCIPAL_AMOUNT].to_f}
          total_interest = projections.inject(0) {|sum, projection| sum + projection[:CPJ_INTEREST_AMOUNT].to_f}

          {
            as_of_date: as_of_date.to_date,
            total_net_amount: total_net_amount,
            total_principal: total_principal,
            total_interest: total_interest,
            projections: Private.format_projections(projections)
          }
        end

        # private
        module Private
          def self.fake_as_of_date
            today = Time.zone.now.to_date
            if today.wday == 0
              today - 2.days
            elsif today.wday == 1
              today - 3.days
            else
              today - 1.day
            end
          end

          def self.fake_cash_projections(as_of_date)
            fake_data = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'cash_projections.json'))).with_indifferent_access
            total_net_amount = 0
            total_principal = 0
            total_interest = 0
            rows = []
            number_of_rows = as_of_date.day + as_of_date.month
            r = Random.new(as_of_date.to_time.to_i + as_of_date.day)

            number_of_rows.times do |i|
              total_amount = r.rand(19..100000) + r.rand.round(2)
              interest = r.rand(1..100000) + r.rand.round(2)
              principal = r.rand(0..8585000) + r.rand.round(2)
              total_net_amount += total_amount
              total_principal += principal
              total_interest += interest
              rows << {
                  CPJ_SETTLE_DATE: as_of_date + (r.rand(3..14)).days,
                  CPJ_BTC_ACCOUNT_NUMBER: '082131',
                  CPJ_CUSIP: fake_data[:cusips][r.rand(0..(fake_data[:cusips].length - 1))],
                  CPJ_DESC_LINE_1: fake_data[:descriptions][r.rand(0..(fake_data[:descriptions].length - 1))],
                  CPJ_TRANS_CODE: 'MBSD',
                  CPJ_POOL_ID: fake_data[:pools][r.rand(0..(fake_data[:pools].length - 1))],
                  CPJ_UNITS: r.rand(250000..22500000),
                  CPJ_ISSUE_RATE: r.rand(0..6) + r.rand.round(3),
                  CPJ_MATURITY_DATE: as_of_date + (i.days),
                  CPJ_PRINCIPAL_AMOUNT: principal,
                  CPJ_INTEREST_AMOUNT: interest,
                  CPJ_TOTAL_AMOUNT: total_amount
              }.with_indifferent_access
            end
            rows
          end

          def self.format_projections(projections)
            projections.collect do |projection|
              {
                settlement_date: projection[:CPJ_SETTLE_DATE].to_date,
                custody_account: projection[:CPJ_BTC_ACCOUNT_NUMBER].to_s,
                cusip: projection[:CPJ_CUSIP].to_s,
                description: projection[:CPJ_DESC_LINE_1].to_s,
                transaction_code: projection[:CPJ_TRANS_CODE].to_s,
                pool_number: projection[:CPJ_POOL_ID].to_s,
                original_par: projection[:CPJ_UNITS].to_f,
                coupon_rate: projection[:CPJ_ISSUE_RATE].to_f,
                maturity_date: projection[:CPJ_MATURITY_DATE].to_date,
                principal: projection[:CPJ_PRINCIPAL_AMOUNT].to_f,
                interest: projection[:CPJ_INTEREST_AMOUNT].to_f,
                total: projection[:CPJ_TOTAL_AMOUNT].to_f
              }
            end
          end
        end
      end
    end
  end
end
