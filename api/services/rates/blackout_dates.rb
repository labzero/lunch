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
          holidays = fake('calendar_holidays')
          fake_data_relative_to_today.map { |d| MAPI::Services::Rates.get_maturity_date(d, 'D', holidays) }
        end
      end
    end
  end
end