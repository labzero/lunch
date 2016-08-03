module MAPI
  module Services
    module Calendar
      include MAPI::Services::Base
      include MAPI::Shared::Utils

      def self.registered(app)
        service_root '/calendar', app
        swagger_api_root :calendar do
          api do
            key :path, '/holidays/{start_date}/{end_date}'
            operation do
              key :method, 'GET'
              key :summary, 'Retrieve array of bank holidays for given date range'
              key :nickname, :getCalendarHolidays
              key :type, :CalendarHolidays
              parameter do
                key :paramType, :path
                key :name, :start_date
                key :required, true
                key :type, :string
                key :description, 'Start date yyyy-mm-dd for the required bank holiday date range.'
              end
              parameter do
                key :paramType, :path
                key :name, :end_date
                key :required, true
                key :type, :string
                key :description, 'End date yyyy-mm-dd for the required bank holiday date range.'
              end
              response_message do
                key :code, 200
                key :message, 'OK'
              end
              response_message do
                key :code, 400
                key :message, 'Invalid input'
              end
            end
          end
        end

        # Bank holidays
        relative_get "/holidays/:start_date/:end_date" do
          MAPI::Services::Calendar.rescued_json_response(self) do
            start_date      = params[:start_date].to_date
            end_date        = params[:end_date].to_date
            raise MAPI::Shared::Errors::ValidationError.new('Invalid date range: start_date must occur earlier than end_date or on the same day', 'invalid_date_range') unless start_date <= end_date
            {holidays: MAPI::Services::Rates::Holidays.holidays(self, start_date, end_date)}
          end
        end
      end
    end
  end
end