module MAPI
  module Services
    module Rates
      module BlackoutDates
        SQL='SELECT BLACKOUT_DATE FROM WEB_ADM.AO_MATURITY_BLACKOUT_DATES'

        def self.blackout_dates(environment)
          if environment == :production
            begin
              dates = []
              date_cursor = ActiveRecord::Base.connection.execute(SQL)
              while date = date_cursor.fetch()
                dates.push(date)
              end
              dates
            rescue e
              warn(:blackout_dates, e.message)
            end
          else
            JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'blackout_dates.json'))) +
            [Date.today + 1.day, Date.today + 1.week, Date.today + 3.week, Date.today + 1.year].map{ |d| d.strftime( "%d-%^b-%y" )}
          end
        end
      end
    end
  end
end