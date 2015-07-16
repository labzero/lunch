module MAPI
  module Models
    class MemberLettersOfCredit
      include Swagger::Blocks
      swagger_model :MemberLettersOfCredit do
        property :as_of_date do
          key :type, :date
          key :description, 'Date FHLB last calculated Letters of Credit'
        end
        property :total_current_par do
          key :type, :float
          key :description, 'The total current par for given securities'
        end
        property :letters_of_credit do
          key :type, :array
          key :description, 'An array of letters_of_credit objects.'
          items do
            key :'$ref', :LettersOfCreditObject
          end
        end
      end
      swagger_model :LettersOfCreditObject do
        property :lc_number do
          key :type, :string
          key :description, 'The letter of credit number'
        end
        property :current_par do
          key :type, :integer
          key :description, 'Current Par'
        end
        property :annual_maintenance_charge do
          key :type, :integer
          key :description, 'Annual maintenance charge (i.e. LCX_TRANS_SPREAD)'
        end
        property :trade_date do
          key :type, :date
          key :description, 'Date letter of credit was traded'
        end
        property :settlement_date do
          key :type, :date
          key :description, 'Settlement date for letter of credit'
        end
        property :maturity_date do
          key :type, :date
          key :description, 'Date at which letter of credit matures'
        end
        property :description do
          key :type, :string
          key :description, 'A description of the letter of credit'
        end
      end
    end
  end
end