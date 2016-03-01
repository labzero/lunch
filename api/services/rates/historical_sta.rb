module MAPI
  module Services
    module Rates
      module HistoricalSTA
        include MAPI::Services::Base
        include MAPI::Shared::Constants

        def self.historical_sta(app, start_date, end_date)
          env = app.settings.environment
          start_date = start_date.to_date
          end_date = end_date.to_date
          irdb = Private.irdb_sql_query(start_date, end_date)
          sta_rate_records = []
          if env == :production
            sta_rates_cursor = ActiveRecord::Base.connection.execute(irdb)
            while sta_rate_row = sta_rates_cursor.fetch_hash()
              sta_rate_records.push(sta_rate_row)
            end
          else
            sta_rate_records = Private.fake_sta_indications(start_date, end_date)
          end
          sta_rates = []
          sta_rate_records.each do |row|
            rates_by_date = {
              'date' =>row['TRX_EFFECTIVE_DATE'].to_date,
              'rate' => row['TRX_VALUE'].to_f
            }
            sta_rates.push(rates_by_date)
          end
          {rates_by_date: sta_rates}
        end

        # private
        module Private
          include MAPI::Shared::Constants

          def self.irdb_sql_query(start_date, end_date)
            <<-SQL
              SELECT TRX_EFFECTIVE_DATE, TRX_VALUE
              FROM IRDB.IRDB_TRANS
              WHERE TRX_IR_CODE ='STARATE'
              AND (TRX_TERM_VALUE || TRX_TERM_UOM  = '1D' )
              AND TRX_EFFECTIVE_DATE BETWEEN to_date(#{ActiveRecord::Base.connection.quote(start_date.strftime('%F'))}, 'yyyy-mm-dd') AND
              to_date(#{ActiveRecord::Base.connection.quote(end_date.strftime('%F'))}, 'yyyy-mm-dd')
              ORDER BY TRX_EFFECTIVE_DATE
            SQL
          end

          def self.fake_sta_indications(start_date, end_date)
            rows = []
            (start_date..end_date).each do |date|
              day_of_week = date.wday
              if day_of_week != 0 && day_of_week != 6
                r = Random.new(date.to_time.to_i)
                value = r.rand.round(5)
                data = {
                  'TRX_EFFECTIVE_DATE' => date.strftime('%F'),
                  'TRX_VALUE' => value,
                }
                rows.push(data)
              end
            end
            rows
          end
        end

      end
    end
  end
end