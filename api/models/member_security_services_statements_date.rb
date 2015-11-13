module MAPI
  module Models
    class MemberSecurityServicesStatementDate
      include Swagger::Blocks
      swagger_model :MemberSecurityServicesStatementDate do
        key :required, %w(report_end_date month_year).map(&:to_sym)
        property :report_end_date do
          key :type, :date
          key :description, 'Report end date'
        end
        property :month_year do
          key :type, :string
          key :description, 'Month/year of report'
        end
      end
    end
  end
end
