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
    end
  end
end