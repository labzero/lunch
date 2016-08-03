module MAPI
  module Models
    class SecuritiesRequest
      include Swagger::Blocks
      swagger_model :SecuritiesRequestForm do
        key :required, %i(request_id form_type status submitted_by submitted_date authorized_by authorized_date settle_date)

        property :request_id do
          key :type, :string
          key :description, 'The ID of the request'
        end

        property :form_type do
          key :type, :string
          key :enum, %i(pledge_intake pledge_release safekept_intake safekept_release)
          key :description, 'What type of form it is'
        end

        property :status do
          key :type, :string
          key :enum, %i(authorized awaiting_authorization)
          key :description, 'What status the form is in'
        end

        property :submitted_by do
          key :type, :string
          key :description, 'The full name of the submitting user'
        end

        property :authorized_by do
          key :type, :string
          key :description, 'The full name of the authorizing user'
        end

        property :submitted_date do
          key :type, :string
          key :format, :date
          key :description, 'The date the form was submitted'
        end

        property :authorized_date do
          key :type, :string
          key :format, :date
          key :description, 'The date the form was authorized'
        end

        property :settle_date do
          key :type, :string
          key :format, :date
          key :description, 'The date the request was settled'
        end
      end

      swagger_model :User do
        key :requred, %i(username full_name session_id)

        property 'username' do
          key :type, :string
          key :description, 'The user name'
        end

        property 'full_name' do
          key :type, :string
          key :description, 'The user\'s full name'
        end

        property 'session_id' do
          key :type, :string
          key :description, 'The user\'s session ID'
        end
      end

      swagger_model :BrokerInstructions do
        key :required, %i(transaction_code settlement_type trade_date settlement_date)

        property :transaction_code do
          key :type, :string
          key :enum, %i(standard repo)
          key :description, 'The transaction code'
        end

        property :settlement_type do
          key :type, :string
          key :enum, %i(free payment)
          key :description, 'The settlement type code'
        end

        property :trade_date do
          key :type, :string
          key :format, :date
          key :description, 'The date of the trade'
        end

        property :settlement_date do
          key :type, :string
          key :format, :date
          key :description, 'The settlement date of the trade'
        end
      end

      swagger_model :DeliveryInstructions do

        property :delivery_type do
          key :required, true
          key :type, :string
          key :enum, %i(fed dtc internal mutual_fund physical_securities)
          key :description, 'To whom to deliver the securties'
        end

        property :clearing_agent_fed_wire_address_1 do
          key :type, :string
          key :description, 'Part 1 of the fed wire address of the clearing agent (a.k.a. broker wire address) when deliver to is fed'
        end

        property :clearing_agent_fed_wire_address_2 do
          key :type, :string
          key :description, 'Part 2 of the fed wire address of the clearing agent (a.k.a. broker wire address) when deliver to is fed'
        end

        property :aba_number do
          key :type, :string
          key :description, 'The ABA number when deliver to is fed'
        end

        property :account_number do
          key :required, true
          key :type, :string
          key :description, 'The credit account number for the delivery type'
        end

        property :clearing_agent_participant_number do
          key :type, :string
          key :description, 'The clearing agent participant number when deliver to is DTC'
        end

        property :mutual_fund_company do
          key :type, :string
          key :description, 'The mutual fund company name when deliver to is mutual fund'
        end

        property :delivery_bank_agent do
          key :type, :string
          key :description, 'The delivery bank agent when deliver to is physical securities'
        end

        property :receiving_bank_agent_name do
          key :type, :string
          key :description, 'The receiving bank agent name when deliver to is physical securities'
        end

        property :receiving_bank_agent_address do
          key :type, :string
          key :description, 'The receiving bank agent address when deliver to is physical securities'
        end
      end

      swagger_model :Security do
        key :required, %i(cusip description original_par payment_amount)

        property :cusip do
          key :type, :string
          key :required, true
          key :description, 'The CUSIP for this security.'
        end

        property :description do
          key :type, :string
          key :required, true
          key :description, 'The description of this security.'
        end

        property :original_par do
          key :type, :number
          key :required, true
          key :description, 'The original par for this security.'
        end

        property :payment_amount do
          key :type, :number
          key :required, true
          key :description, 'The payment amount for this security.'
        end
      end

      swagger_model :SecuritiesRelease do
        key :required, %i(user broker_instructions delivery_instructions securities)

        property :request_id do
          key :type, :string
          key :description, 'The ID of the request'
        end

        property :user do
          key :type, :User
          key :description, 'The user information'
        end

        property :broker_instructions do
          key :type, :BrokerInstructions
          key :description, 'The broker instructions for this release'
        end

        property :delivery_instructions do
          key :type, :DeliveryInstructions
          key :description, 'The delivery instructions for this release'
        end

        property :securities do
          key :type, :array
          key :description, 'An array of securities to be included in the release request.'
          items do
            key :'$ref', :Security
          end
        end
      end

      swagger_model :SecuritiesRequestAuthorization do
        key :required, %i(user request_id)

        property :user do
          key :type, :User
          key :description, 'The user information'
        end

        property :request_id do
          key :type, :string
          key :required, true
          key :description, 'The request ID of the request to authorize.'
        end
      end

      swagger_model :SecuritiesReleaseResponse do
        property :request_id do
          key :type, :string
          key :required, true
          key :description, 'The request ID of the newly created request.'
        end
      end
    end
  end
end