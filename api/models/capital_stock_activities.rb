module MAPI
  module Models
    class CaptialStockActivities
      include Swagger::Blocks
      swagger_model :CapitalStockActivities do
        property :open_balance do
          key :type, :string
          key :description, 'Opening Capital Stock balance at close of business day of the selected start date'
        end
        property :open_cert_number do
          key :type, :string
          key :description, 'Opening Capital Stock share count at close of business day of the selected start date'
        end
        property :close_balance do
          key :type, :string
          key :description, 'Opening Capital Stock balance at close of business day of the selected end date'
        end
        property :close_cert_number do
          key :type, :string
          key :description, 'Opening Capital Stock share count at close of business day of the selected end date'
        end
        #TODO how to declare nested where the below is nested in the activities hash
        property :cert_id do
          key :type, :string
          key :description, 'Cert ID'
        end
        property :share_number do
          key :type, :string
          key :description, 'Number of share in the transaction'
        end
        property :amount do
          key :type, :string
          key :description, '$ Amount of the transaction'
        end
        property :class do
          key :type, :string
          key :description, 'Share class type'
        end
        property :full_partial_ind do
          key :type, :string
          key :description, 'Indicate if this is a Full or Partial repurchase'
        end
        property :trans_id do
          key :type, :string
          key :description, 'Transaction id for this activity'
        end
        property :trans_date do
          key :type, :string
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