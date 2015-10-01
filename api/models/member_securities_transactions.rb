module MAPI
  module Models
    class MemberSecuritiesTransactions
      include Swagger::Blocks
      swagger_model :MemberSecuritiesTransactions do
        property :final do
          key :type, :boolean
          key :description, 'Have the transactions been finalized?'
        end
        property :transactions do
          key :type, :array
          key :description, 'An array of securities transactions.'
          items do
            key :'$ref', :SecurityTransactionObject
          end
        end
      end
      swagger_model :SecurityTransactionObject do
        property :fhlb_id do
          key :type, :number
          key :description, 'FHLB Member id'
        end
        property :custody_account_no do
          key :type, :string
          key :description, 'Custody account number'
        end
        property :new_transaction do
          key :type, :boolean
          key :description, "Is this a new transaction?"
        end
        property :cusip do
          key :type, :string
          key :description, 'CUSIP Identifier'
        end
        property :transaction_code do
          key :type, :string
          key :description, "Transaction code"
        end
        property :security_description do
          key :type, :string
          key :description, "A description of the security"
        end
        property :units do
          key :type, :float
          key :description, 'Units'
        end
        property :maturity_date do
          key :type, :date
          key :description, 'Maturity Date of security'
        end
        property :payment_or_principal do
          key :type, :float
          key :description, 'Payment or principle'
        end
        property :interest do
          key :type, :float
          key :description, 'Interest'
        end
        property :total_amount do
          key :type, :float
          key :description, 'Total amount'
        end
      end
    end
  end
end