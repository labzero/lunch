module MAPI
  module Services
    module Member
      module CapitalStock
        # capital stock balance
        def self.capital_stock_balance(app, member_id, balance_date )
          member_id = member_id.to_i
          capstock_balance_open_connection_string = <<-SQL
            SELECT sum(no_share_holding) as open_balance_cf FROM capstock.capstock_shareholding
            WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
            AND (sold_date is null or sold_date >= to_date(#{ActiveRecord::Base.connection.quote(balance_date)}, 'yyyy-mm-dd') )
            AND purchase_date < to_date(#{ActiveRecord::Base.connection.quote(balance_date)}, 'yyyy-mm-dd')
            GROUP BY fhlb_id
          SQL

          capstock_balance_close_connection_string = <<-SQL
             SELECT sum(no_share_holding) as open_balance_cf FROM capstock.capstock_shareholding
             WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
             AND (sold_date is null or sold_date > to_date(#{ ActiveRecord::Base.connection.quote(balance_date)}, 'yyyy-mm-dd') )
             AND purchase_date <= to_date(#{ ActiveRecord::Base.connection.quote(balance_date)}, 'yyyy-mm-dd')
             GROUP BY fhlb_id
          SQL

          if app.settings.environment == :production
            cp_open_cursor = ActiveRecord::Base.connection.execute(capstock_balance_open_connection_string)
            cp_close_cursor = ActiveRecord::Base.connection.execute(capstock_balance_close_connection_string)
            open_balance = (cp_open_cursor.fetch() || [nil])[0]
            close_balance = (cp_close_cursor.fetch() || [nil])[0]
          else
            results = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'capital_stock_balances.json'))).with_indifferent_access
            open_balance = results[:open_balance]
            close_balance = results[:close_balance]
          end
          {
              open_balance: (open_balance || 0).to_f,
              close_balance: (close_balance || 0).to_f,
              balance_date: balance_date.to_date
          }.to_json
        end

        # capital stock activities
        def self.capital_stock_activities(app, member_id, from_date, to_date)
          member_id = member_id.to_i
          capstockactivities_transactions_connection_string = <<-SQL
          SELECT CERT_ID, NO_SHARE, TRAN_DATE, NVL(TRAN_TYPE, '-') TRAN_TYPE, NVL(DR_CR, '-') DR_CR
          FROM CAPSTOCK.ACCOUNT_ACTIVITY_V Vw
          WHERE fhlb_id = #{ActiveRecord::Base.connection.quote(member_id)}
          AND tran_date >= to_date(#{ActiveRecord::Base.connection.quote(from_date)}, 'yyyy-mm-dd')
          AND tran_date <= to_date(#{ActiveRecord::Base.connection.quote(to_date)}, 'yyyy-mm-dd')
          SQL

          if app.settings.environment == :production
            cp_trans_cursor = ActiveRecord::Base.connection.execute(capstockactivities_transactions_connection_string)
            activities = []
            while row = cp_trans_cursor.fetch()
              hash = {"cert_id" => row[0],
                      "share_number" => row[1],
                      "trans_date" => row[2],
                      "trans_type" => row[3],
                      "dr_cr" => row[4]}
              activities.push(hash)
            end
          else
            results = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'capital_stock_activities.json'))).with_indifferent_access
            activities = []
            to_date_obj = Date.parse(to_date)
            from_date_obj = Date.parse(from_date)
            results["Activities"].each do |activity|
              hash = {"cert_id" => activity["cert_id"],
                      "share_number" => activity["share_number"],
                      "trans_date" => Date.parse(activity["trans_date"]),
                      "trans_type" => activity["trans_type"],
                      "dr_cr" => activity["dr_cr"]
              }
              activities.push(hash) if hash["trans_date"] >= from_date_obj && hash["trans_date"] <= to_date_obj
            end
          end
          activities_formatted = []
          activities.each do |row|
            hash = {"cert_id" => row["cert_id"].to_s,
                    "share_number" => row["share_number"].to_f,
                    "trans_date" => row["trans_date"].to_date,
                    "trans_type" => row["trans_type"].to_s,
                    "dr_cr" => row["dr_cr"].to_s
            }
            activities_formatted.push(hash)
          end
          {
              activities: activities_formatted
          }.to_json
        end
       end
    end
  end
end