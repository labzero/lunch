module MAPI
  module Models
    class HistoricalSTA
      include Swagger::Blocks
      swagger_model :HistoricalSTA do
        property :date do
          key :type, :date
          key :description, 'The date for this rate'
        end
        property :rate do
          key :type, :string
          key :description, 'The rate of this sta'
        end
      end
    end
  end
end
