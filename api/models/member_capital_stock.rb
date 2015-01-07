module MAPI
  module Models
    class CapitalStockBalance
      include Swagger::Blocks
      swagger_model :CapitalStockBalance do
        property :open_balance do
          key :type, :number
          key :description, 'Capital Stock Open balance of the selected start date'
        end
        property :close_balance do
          key :type, :number
          key :description, 'Capital Stock Close balance of the selected start date'
        end
        property :balance_date do
          key :type, :date
          key :description, 'Date for the Capital Stock balances'
        end
      end
    end
    class CapitalStockActivities
      include Swagger::Blocks
      swagger_model :CapitalStockActivities do
        property :cert_id do
          key :type, :string
          key :description, 'Cert ID'
        end
        property :share_number do
          key :type, :number
          key :description, 'Number of share in the transaction'
        end
        property :trans_date do
          key :type, :date
          key :description, 'Date of this transaction'
        end
        property :trans_type do
          key :type, :string
          key :description, 'Type of transaction e.g. Repurchase, Purchase, Dividend ect.'
        end
        property :dr_cr do
          key :type, :string
          key :description, 'Indicate if this is a Credit or Debit activity'
        end
      end
    end
  end
end
