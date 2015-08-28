module MAPI
  module Services
    module Rates
      module BlackoutDates
        SQL='SELECT BLACKOUT_DATE FROM WEB_ADM.AO_MATURITY_BLACKOUT_DATES'

        def self.blackout_dates(logger, environment)
          environment == :production ? blackout_dates_production(logger) : blackout_dates_development
        end

        def self.blackout_dates_production(logger)
          begin
            dates = []
            date_cursor = ActiveRecord::Base.connection.execute(SQL)
            while date = date_cursor.fetch()
              dates += date
            end
            dates
          rescue => e
            logger.error( "blackout_dates_production encountered the following error: #{e.message}" )
          end
        end

        def self.fake_data_fixed
          JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'blackout_dates.json'))).map{ |d| Date.parse(d) }
        end

        def self.fake_data_relative_to_today

          JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'blackout_dates.json'))).map{ |d| Date.parse(d) }
          [Date.today + 1.week, Date.today + 3.week]
        end

        def self.blackout_dates_development
          (fake_data_relative_to_today + fake_data_fixed).map { |d| nearest_business_day(d) }
        end

        def self.nearest_business_day(d)
          return d unless d.saturday? || d.sunday?
          self.nearest_business_day(d + 1.day)
        end
      end
    end
  end
end