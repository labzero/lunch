module MAPI
  module Services
    module Rates
      module BlackoutDates
        include MAPI::Shared::Utils

        SQL='SELECT BLACKOUT_DATE FROM WEB_ADM.AO_MATURITY_BLACKOUT_DATES'

        def self.blackout_dates(logger, environment)
          environment == :production ? blackout_dates_production(logger) : blackout_dates_development
        end

        def self.blackout_dates_production(logger)
          fetch_objects(logger, SQL)
        end

        def self.fake_data_relative_to_today
          today = Time.zone.today
          [today + 1.week, today + 3.week]
        end

        def self.blackout_dates_development
          fake_data_relative_to_today.map { |d| nearest_business_day(d) }
        end

        def self.nearest_business_day(d)
          return d unless d.saturday? || d.sunday?
          self.nearest_business_day(d + 1.day)
        end
      end
    end
  end
end