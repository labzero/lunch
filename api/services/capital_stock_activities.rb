module MAPI
  module Services
    module CaptialStockActivities
      include MAPI::Services::Base

      def self.registered(app)
        service_root '/capital_stock', app
        swagger_api_root :capital_stock do
          api do
            key :path, "/{id}/{from_date}/{to_date}/activities"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve Capital Stock Activities transactions with start and close balances.'
              key :notes, 'Returns Capital Stock Activities and Open/Close balance for the selected periord.'
              key :type, :CapitalStockActivities
              key :nickname, :getCapitalStockActivitiesForMember
              parameter do
                key :paramType, :path
                key :name, :id
                key :required, true
                key :type, :string
                key :description, 'The id to find the members from'
              end
              parameter do
                key :paramType, :path
                key :name, :from_date
                key :required, true
                key :type, :string
                key :description, 'Start date yyyy-mm-dd for the Capital Stock Activities Report.'
              end
              parameter do
                key :paramType, :path
                key :name, :to_date
                key :required, true
                key :type, :string
                 key :description, 'End date yyyy-mm-dd for the Capital Stock Activities Report.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 404
                key :message, 'Invalid input'
              end
            end
          end
        end
        # capital stock activities
        relative_get "/:id/:from_date/:to_date/activities" do
          member_id = params[:id]
          from_date = params[:from_date]
          to_date = params[:to_date]
          m = /\A\d\d\d\d-(0\d|1[012])-([0-2]\d|3[01])\Z/
        #TODO check that input for from and to dates are valid date and expected format


          capstockactivities_start_connection_string = <<-SQL
          SELECT sum(no_share_holding) as open_balance_cf, count(*) no_cert_cf
          FROM capstock.capstock_shareholding
          WHERE fhlb_id = #{member_id}
          AND (sold_date is null or sold_date >= to_date(#{from_date}, 'yyyy-mm-dd') )
          AND purchase_date < to_date(#{from_date}, 'yyyy-mm-dd')
          GROUP BY fhlb_id
          SQL

          capstockactivities_end_connection_string = <<-SQL
          SELECT sum(no_share_holding) as end_balance_cf, count(*) no_cert_cf
          FROM capstock.capstock_shareholding
          WHERE fhlb_id = #{member_id}
          AND (sold_date is null or sold_date > to_date(#{to_date}, 'yyyy-mm-dd') )
          AND purchase_date <= to_date(#{to_date}, 'yyyy-mm-dd')
          GROUP BY fhlb_id
          SQL

          capstockactivities_transactions_connection_string = <<-SQL
          SELECT CERT_ID, NO_SHARE, AMOUNT, CLASS, NVL(FULL_PARTIAL_IND, '-') FULL_PARTIAL_IND ,
          TRAN_ID, TRAN_DATE, NVL(TRAN_TYPE, '-') TRAN_TYPE, NVL(DR_CR, '-') DR_CR
          FROM CAPSTOCK.ACCOUNT_ACTIVITY_V Vw
          WHERE fhlb_id = #{member_id}
          AND tran_date >= to_date(#{from_date}, 'yyyy-mm-dd')
          AND tran_date <= to_date(#{to_date}, 'yyyy-mm-dd')
          SQL

          if settings.environment == :production
            cp_start_cursor = ActiveRecord::Base.connection.execute(capstockactivities_start_connection_string)
            cp_end_cursor = ActiveRecord::Base.connection.execute(capstockactivities_end_connection_string)
            cp_trans_cursor = ActiveRecord::Base.connection.execute(capstockactivities_transactions_connection_string)

            while row = cp_start_cursor.fetch()
              open_balance = row[0]
              open_cert_count = row[1]
            end
            while row = cp_end_cursor.fetch()
              close_balance = row[0]
              close_cert_count = row[1]
            end
            activities = Array.new
            while row = cp_trans_cursor.fetch()
              hash = {"cert_id" => row[0],
                  "share_number" => row[1],
                  "amount" => row[2],
                  "class" => row[3],
                  "full_partial_ind" => row[4],
                  "tran_id" => row[5],
                  "trans_date" => row[6],
                  "trans_type" => row[7],
                  "dr_cr" => row[8]}
              activities.push(hash)
            end

            {
              open_balance: open_balance,
              open_cert_count: open_cert_count,
              close_balance: close_balance,
              close_cert_count: close_cert_count,
              activities: activities
            }.to_json
          else
            File.read(File.join(MAPI.root, 'fakes', 'capital_stock_activities.json'))
          end
        end
      end
    end
  end
end