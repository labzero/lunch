module MAPI
  module Models
    class CollateralWireFees
      include Swagger::Blocks
      swagger_model :CollateralFeesStatement do
        [:custody_fee, :review_fee, :release_fee, :processing_fee].each do |fee_type|
          property fee_type do
            key :required, true
            key :type, :CollateralFeesStatementObject
            key :description, "An object containing the fee information for the `#{fee_type}`"
          end
        end
      end
      swagger_model :CollateralFeesStatementObject do
        key :required, [:count, :cost, :total]
        property :count do
          key :type, :integer
          key :description, 'Number of items charged for for this period.'
        end
        property :cost do
          key :type, :number
          key :description, 'Custody fee charged per item.'
          key :notes, 'Expressed in dollars and cents out to 2 decimal places (e.g. 1.35).'
        end
        property :total do
          key :type, :number
          key :description, 'Total charge for this fee type and period (rate * count).'
          key :notes, 'Expressed in dollars and cents out to 2 decimal places (e.g. 14.72).'
        end
      end
    end
  end
end