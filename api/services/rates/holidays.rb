require 'savon'

module MAPI
  module Services
    module Rates
      module Holidays
        include MAPI::Services::Base
        include MAPI::Shared::Constants

        def self.get_holidays_from_soap(logger, connection, start, finish)
          begin
            connection.call(:get_holiday,
                                  message_tag: 'holidayRequest',
                                  message: {'v1:endDate' => finish, 'v1:startDate' => start},
                                  soap_header: SOAP_HEADER)
          rescue Savon::Error => error
            logger.error error
            nil
          end
        end

        def self.holidays(logger, environment, start=Time.zone.today, finish=Time.zone.today + 3.years)
          if connection = MAPI::Services::Rates.init_cal_connection(environment)
            if response = get_holidays_from_soap(logger, connection, start, finish)
              response.doc.remove_namespaces!
              r1 = response.doc.xpath('//Envelope//Body//holidayResponse//holidays//businessCenters')
              return [] if r1.blank?
              r1[0].css('days day date').map { |holiday| Time.zone.parse(holiday.content) }
            else
              []
            end
          else
            MAPI::Services::Rates.fake('calendar_holidays')
          end
        end
      end
    end
  end
end
