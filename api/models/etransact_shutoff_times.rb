module MAPI
  module Models
    class EtransactLimitsArray
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
    end
  end
end

