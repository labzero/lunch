module MAPI
  module Models
    class MemberCapitalStockTrialBalance
      include Swagger::Blocks
      swagger_model :MemberCapitalStockTrialBalance do
        key :required, [:fhlb_id, :number_of_shares, :number_of_certificates, :certificates]
        property :fhlb_id do
          key :type, :integer
          key :description, 'Member id'
        end
        property :number_of_shares do
          key :type, :integer
          key :description, 'Number of shares'
        end
        property :number_of_certificates do
          key :type, :integer
          key :description, 'Number of certificates'
        end
        property :certificates do
          key :type, :array
          key :description, 'An array of certificate objects.'
          items do
            key :'$ref', :CertificateObject
          end
        end
      end
      swagger_model :CertificateObject do
        key :required, [:certificate_sequence, :class, :issue_date, :shares_outstanding, :transaction_type]
        property :certificate_sequence do
          key :type, :integer
          key :description, 'Certificate sequence'
        end
        property :class do
          key :type, :string
          key :description, 'Certificate class'
        end
        property :issue_date do
          key :type, :date
          key :description, 'Issue date'
        end
        property :shares_outstanding do
          key :type, :integer
          key :description, 'Shares outstanding'
        end
        property :transaction_type do
          key :type, :string
          key :description, 'Transaction type'
        end
      end
    end
  end
end
