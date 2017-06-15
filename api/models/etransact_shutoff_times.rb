module MAPI
  module Models
    class EtransactShutoffTimes
      include Swagger::Blocks
      swagger_model :ShutoffTimesByType do
        key :required, [:vrc, :frc]
        property :vrc do
          key :type, :string
          key :description, 'A 4-character string corresponding to the time of day the VRC advance buckets will shut off. Values from `0000` to `2400`'
        end
        property :frc do
          key :type, :string
          key :description, 'A 4-character string corresponding to the time of day the FRC advance buckets will shut off. Values from `0000` to `2400`'
        end
      end
      swagger_model :EarlyShutoff do
        key :required, [:early_shutoff_date, :vrc_shutoff_time, :frc_shutoff_time, :day_of_message, :day_before_message]
        property :original_early_shutoff_date do
          key :required, false
          key :type, :string
          key :description, 'The ISO-8601 string representation of the original date for the early shutoff that is to be updated. Format is YYYY-MM-DD'
          key :notes, 'Only applies to the PUT `etransact_advances\early_shutoff` endpoint.'
        end
        property :early_shutoff_date do
          key :type, :string
          key :description, 'The ISO-8601 string representation of the date for the early shutoff. Format is YYYY-MM-DD'
        end
        property :vrc_shutoff_time do
          key :type, :string
          key :description, 'A 4-character string corresponding to the time of day the VRC advance buckets will shut off on the scheduled shutoff date. Values from `0000` to `2400`'
        end
        property :frc_shutoff_time do
          key :type, :string
          key :description, 'A 4-character string corresponding to the time of day the FRC advance buckets will shut off on the scheduled shutoff date. Values from `0000` to `2400`'
        end
        property :day_of_message do
          key :type, :string
          key :description, 'The message to display on the day the early shutoff is scheduled.'
        end
        property :day_before_message do
          key :type, :string
          key :description, 'The message to display the business day before the early shutoff is scheduled.'
        end
      end
    end
  end
end

