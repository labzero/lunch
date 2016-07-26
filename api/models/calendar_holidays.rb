module MAPI
  module Models
    class CalendarHolidays
      include Swagger::Blocks
      swagger_model :CalendarHolidays do
        property :holidays do
          key :type, :array
          key :description, 'An array of holiday dates in "YYYY-MM-DD" format.'
          items do
            key :type, :string
            key :description, 'A bank holiday in "YYYY-MM-DD" format.'
          end
        end
      end
    end
  end
end