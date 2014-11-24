module MAPI
  module Services
    module Rates
      include MAPI::Services::Base

      def self.registered(app)
        @connection = ActiveRecord::Base.establish_connection('cdb').connection if MAPI.env == 'production'

        service_root '/rates', app
        swagger_api_root :rates do
          api do
            key :path, "/historic/overnight"
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve historic overnight rates'
              key :notes, 'Returns a list of the opening overnight rates'
              key :type, :Rate
              key :nickname, :historticOvernightVRCRate
              parameter do
                key :paramType, :query
                key :name, :limit
                key :required, false
                key :type, :integer
                key :defaultValue, 30
                key :minimum, 0
                key :maximum, 30
                key :description, 'How many rates to return. Default is 30.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
            end
          end
        end

        relative_get "/historic/overnight" do
          days = (params[:limit] || 30).to_i
          connection_string = <<-SQL
              SELECT * FROM (SELECT TRX_EFFECTIVE_DATE, TRX_VALUE
              FROM IRDB.IRDB_TRANS T
              WHERE TRX_IR_CODE = 'FRADVN'
              AND (TRX_TERM_VALUE || TRX_TERM_UOM  = '1D' )
              ORDER BY TRX_EFFECTIVE_DATE DESC) WHERE ROWNUM <= #{days}
          SQL

          data = if @connection
            cursor = @connection.execute(connection_string)
            rows = []
            while row = cursor.fetch()
              rows.push([row[0], row[1]])
            end
            rows
          else
            rows = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'rates_historic_overnight.json')))[0..(days - 1)]
            rows.collect do |row|
              [Date.parse(row[0]), row[1]]
            end
          end

          data.reverse!.collect! do |row|
            [row[0].to_date, row[1].to_f]
          end

          data.to_json
        end
      end
    end
  end
end