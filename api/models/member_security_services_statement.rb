module MAPI
  module Models
    class MemberSecurityServicesStatement
      include Swagger::Blocks
      swagger_model :MemberSecurityServicesStatement do
        key :required, %w(account_maintenance certifications handling income_disbursement pledge_status_change research securities_fees sta_account_number total transaction_fees).map(&:to_sym)

        property :sta_account_number do
          key :type, :string
          key :description, 'STA Account Number'
        end
        property :total do
          key :type, :float
          key :description, 'Total fees'
        end
        property :account_maintenance do
          key :type, :Total
          key :description, 'Account maintenance'
        end
        %w(income_disbursement pledge_status_change certifications research handling).each do |field|
          property field.to_sym do
            key :type, :CountCostTotal
            key :description, field
          end
        end
        %w(securities_fees transaction_fees).each do |field|
          property field.to_sym do
            key :type, :MemberSecurityServicesStatementFees
            key :required, true
            key :description, field
          end
        end
      end

      swagger_model :Total do
        property :total do
          key :type, :float
          key :required, true
          key :description, 'total'
        end
      end

      swagger_model :CountCostTotal do
        property :count do
          key :type, :number
          key :required, true
          key :description, 'count'
        end
        property :cost do
          key :type, :float
          key :required, true
          key :description, 'cost'
        end
        property :total do
          key :type, :float
          key :required, true
          key :description, 'total'
        end
      end

      swagger_model :MemberSecurityServicesStatementFees do
        %w(fed dtc funds euroclear).each do |field|
          property field.to_sym do
            key :type, :CountCostTotal
            key :required, true
            key :description, field
          end
        end
      end
    end
  end
end