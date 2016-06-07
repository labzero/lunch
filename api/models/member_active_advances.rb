module MAPI
  module Models
    class ActiveAdvances
      include Swagger::Blocks
      swagger_model :ActiveAdvances do
        key :required, [:trade_date, :funding_date, :maturity_date, :advance_number, :advance_type, :status, :interest_rate, :current_par, :trade_time, :advance_confirmation]
        property :trade_date do
          key :type, :string
          key :format, :'date-time'
          key :description, 'Advances Trade DateTime'
        end
        property :funding_date do
          key :type, :string
          key :format, :date
          key :description, 'Advances Funding/Settlement Date'
        end
        property :maturity_date do
          key :type, :string
          key :format, :date
          key :description, 'Advances Maturity Date or Open in cases for OPEN VRC advances'
        end
        property :advance_number do
          key :type, :string
          key :description, 'Advances number'
        end
        property :advance_type do
          key :type, :string
          key :description, 'Description of the Advances type'
        end
        property :status do
          key :type, :string
          key :description, 'Processing or Outstanding'
        end
        property :interest_rate do
          key :type, :Numeric
          key :description, 'Advances interest rate.  It could be up to 5 decimal points.'
        end
        property :current_par do
          key :type, :Numeric
          key :description, 'Advances current par'
        end
        property :trade_time do
          key :type, :string
          key :description, 'The time an advance was traded.'
        end
        property :advance_confirmation do
          key :type, :array
          key :description, 'An array of confirmation objects.'
          items do
            key :'$ref', :AdvanceConfirmationObject
          end
        end
      end
      swagger_model :AdvanceConfirmationObject do
        property :member_id do
          key :type, :string
          key :description, 'The id of the member'
          key :note, 'Used for validating download of advance confirmation attachment'
        end
        property :confirmation_date do
          key :type, :string
          key :format, :date
          key :description, 'Date of advance confirmation'
        end
        property :advance_number do
          key :type, :string
          key :description, 'Advances number'
        end
        property :confirmation_number do
          key :type, :string
          key :description, 'Advance confirmation number'
        end
        property :file_location do
          key :type, :string
          key :description, 'A pointer to the location of the confirmation advance attachment'
        end
      end
    end
  end
end
