require 'savon'

module MAPI
  module Shared
    module CalendarHolidayServices

      def self.init_calendar_connection(environment)
        if environment == :production
          @@calendar_uk_connection = Savon.client(
              wsdl: ENV['MAPI_CALENDAR_ENDPOINT'],
              env_namespace: :soapenv,
              namespaces: { 'xmlns:v1' => 'http://fhlbsf.com/schema/msg/businessCalendar/v1',
                            'xmlns:wsse' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd',
                            'xmlns:v1' =>'http://fhlbsf.com/schema/msg/businessCalendar/v1',
                            'xmlns:v11' => 'http://fhlbsf.com/schema/canonical/common/v1'},
              element_form_default: :qualified,
              namespace_identifier: :v1,
              pretty_print_xml: true
          )
        else
          @@calendar_uk_connection = nil
        end
      end

      def self.calendar_holiday_london_only(from_date, to_date,  environment)
        MAPI::Shared::CalendarHolidayServices::init_calendar_connection(environment)
        data = if @@calendar_uk_connection
          message = {'v1:endDate' => to_date , 'v1:startDate' => from_date }
          begin
            response = @@client.call(:get_holiday, message_tag: 'holidayRequest', message: message, :soap_header => {'wsse:Security' => {'wsse:UsernameToken' => {'wsse:Username' => ENV['MAPI_FHLBSF_ACCOUNT'], 'wsse:Password' => ENV['SOAP_SECRET_KEY']}}})
            rescue Savon::Error => error
              {}
          else
            holiday_london = []
            holiday_us = []
            only_london = []
            special_pricing = []
            if response.success?
              response.doc.remove_namespaces!
              holiday_type = response.doc.xpath('//Envelope//Body//holidayResponse//holidays//businessCenters')
              holiday_type.each do |row|
                case row.css('businessCenter').text
                  when 'USNY'
                    @@holidaysUSNY = row.css('days day date').map do |holiday|
                      holiday_us.push(Date.parse(holiday.content))
                    end
                  when 'London'
                    @@holidaysLondon = row.css('days day date').map do |holiday|
                      holiday_london.push(Date.parse(holiday.content))
                    end
                  else
                    @@holidaysspecial = row.css('days day date').map do |holiday|
                      special_pricing.push(Date.parse(holiday.content))
                    end
                end
              end
              #get London holiday that is not US holiday or weekend
              holiday_london.each do |rowlon|
                holiday_date = Date.parse(rowlon.to_s)
                if (holiday_us.include?(holiday_date) || holiday_date.saturday? || holiday_date.sunday?) ? false : true
                  only_london.push(holiday_date)
                end
              end
              data = {"london_holidy" => only_london}
              data
            else
              {}
            end
          end
        else
            # We have no real data source yet.
            data = JSON.parse(File.read(File.join(MAPI.root, 'fakes', 'calendar_london_only_holiday.json')))
            data
        end
      end
    end
  end
end