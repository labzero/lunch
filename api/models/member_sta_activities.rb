module MAPI
  module Models
    class STAActivities
      include Swagger::Blocks
      swagger_model :STAActivities do
        property :start_balance do
          key :type, :Numeric
          key :description, 'STA activities Beginning Balance value '
        end
        property :start_date do
          key :type, :date
          key :description, 'STA activities Beginning Balance Date'
        end
        property :end_balance do
          key :type, :Numeric
          key :description, 'STA activities Ending Balance value '
        end
        property :end_date do
          key :type, :date
          key :description, 'STA activities Ending Balance Date'
        end
        property :activities do
          key :type, :STAActivitiesObject
          key :description, 'An object containing etransact status for each of the specified loan_term and loan_type'
        end
      end
      swagger_model :STAActivitiesObject do
        property :trans_date do
          key :type, :date
          key :description, 'Transaction date of the activity'
        end
        property :refnumber do
          key :type, :string
          key :description, 'Reference number of the activity or null'
        end
        property :descr do
          key :type, :string
          key :description, 'Description of the activity'
        end
        property :credit do
          key :type, :Numeric
          key :description, 'Credit amount of the activity or null'
        end
        property :debit do
          key :type, :Numeric
          key :description, 'Debit amount of the activity or null'
        end
        property :rate do
          key :type, :Numeric
          key :description, 'Interest rate or 0'
        end
        property :balance do
          key :type, :Numeric
          key :description, 'Closing balance for the day or null'
        end
      end
    end
  end
end