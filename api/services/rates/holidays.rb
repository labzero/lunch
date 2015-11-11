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

        def self.holidays(logger, environment)
          if connection = MAPI::Services::Rates.init_cal_connection(environment)
            return nil unless response = get_holidays_from_soap(logger, connection, Time.zone.today, Time.zone.today + 3.years)
            response.doc.remove_namespaces!
            response.doc.xpath('//Envelope//Body//holidayResponse//holidays//businessCenters')[0].css('days day date').map do |holiday|
              Time.zone.parse(holiday.content)
            end
          else
            MAPI::Services::Rates.fake('calendar_holidays')
          end
        end
      end
    end
  end
end
