module MAPI
  module Services
    module EtransactAdvances
      include MAPI::Services::Base
      STATUS_ON_RECORD_NOTFOUND_COUNT = 0

      def self.registered(app)
        @connection = ActiveRecord::Base.establish_connection('cdb').connection if app.environment == 'production'

        service_root '/etransact_advances', app
        swagger_api_root :etransact_advances do

          # etransact advances status endpoint
          api do
            key :path, '/status'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve status of etransact Advances today'
              key :notes, 'Return status if etransact is turn on for the day and if all products reached it end time for the day'
              key :type, :etransactAdvancesStatus
              key :nickname, :getEtransactAdvancesStatus
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
        end

        # etransact advances status
        relative_get "/status" do
          etransact_advances_turn_on_string = <<-SQL
            SELECT count(*) as status_on_count
            FROM WEB_ADM.AO_SETTINGS
            WHERE SETTING_NAME = 'StartUp'
            AND trunc(to_date(SETTING_VALUE, 'MM/dd/yyyy')) = trunc(sysdate)
          SQL

          etransact_advances_eod_on_string = <<-SQL
            SELECT count(*)
            FROM WEB_ADM.AO_TERM_BUCKETS
            WHERE (END_TIME || '00' > to_char(sysdate, 'HH24MISS')) OR
            ((trunc(OVERRIDE_END_DATE) = trunc(sysdate))
            AND (OVERRIDE_END_TIME || '00' > TO_CHAR(SYSDATE, 'HH24MISS')))
          SQL

          etransact_advances_WLVRC_on_string = <<-SQL
            SELECT count(*) AS WL_VRC_status
            FROM WEB_ADM.AO_TERM_BUCKETS
            WHERE WHOLE_LOAN_ENABLED = 'Y' AND AO_TERM_BUCKET_ID = 1
          SQL

          if @connection
            etransact_status = false  #indicat if etransact is turn on and at least one product has not reach End Time
            wl_vrc_status = false   #indicate if WL VRC is enabled regardless of if etransact is turn on
            etransact_eod_status_on_cursor = @connection.execute(etransact_advances_eod_on_string)
            while row = etransact_eod_status_on_cursor.fetch()
              if row[0].to_i > STATUS_ON_RECORD_NOTFOUND_COUNT
                etransact_status = true
              end
            end
            if etransact_status
              etransact_status_on_cursor = @connection.execute(etransact_advances_turn_on_string)
              while row = etransact_status_on_cursor.fetch()
                if row[0].to_i = STATUS_ON_RECORD_NOTFOUND_COUNT
                  etransact_status = false
                end
              end
            end
            etransact_wl_status_on_cursor = @connection.execute(etransact_advances_WLVRC_on_string)
            while row = etransact_wl_status_on_cursor.fetch()
              if row[0].to_i == STATUS_ON_RECORD_FOUND_COUNT
                wl_vrc_status = true
              end
            end
            {
              etransact_status: etransact_status,
              wl_vrc_status: wl_vrc_status
            }.to_json
          else
            File.read(File.join(MAPI.root, 'fakes', 'etransact_advances_status.json'))
          end
        end
      end
    end
  end
end