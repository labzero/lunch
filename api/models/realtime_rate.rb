module MAPI
  module Models
    class RealtimeRate
      include Swagger::Blocks
      swagger_model :RealtimeRate do
        property :rate do
          key :type, :number
          key :format, :float
          key :description, 'the rate'
          key :minimum, '0.0'
        end
        property :updated_at do
          key :type, :dateTime
          key :description, 'when the rate was last updated'
        end
      end
    end
  end
end