module MAPI
  module Services
    module Rates
      module BlackoutDates
        SQL='SELECT BLACKOUT_DATE FROM WEB_ADM.AO_MATURITY_BLACKOUT_DATES'

        def self.blackout_dates(environment)
          if environment == :production
            v = []
            v_cursor = ActiveRecord::Base.connection.execute(SQL)
            while row = v_cursor.fetch()
              v.push(row)
            end
            v
          else
            JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'blackout_dates.json'))) +
            [Date.today + 1.day, Date.today + 1.week, Date.today + 3.week, Date.today + 1.year]
          end
        end
      end
    end
  end
end