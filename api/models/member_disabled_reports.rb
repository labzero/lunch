module MAPI
  module Models
    class DisabledReports
      include Swagger::Blocks
      swagger_model :DisabledReports do
        property :disabled_report_ids do
          key :type, :array
          items do
            key :type, :integer
          end
        end
      end
    end
  end
end