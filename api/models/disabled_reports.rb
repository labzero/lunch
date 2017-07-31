module MAPI
  module Models
    class DisabledReports
      include Swagger::Blocks
      swagger_model :GlobalDisabledReports do
        property :web_flag_id do
          key :required, true
          key :type, :integer
          key :description, 'The `web_flag_id` corresponding to the data on the Member Portal that should be displayed or not depending on the `visible` setting.'
        end
        property :visible do
          key :required, true
          key :type, :boolean
          key :description, 'The boolean value indicating whether the data associated with the given `web_flag_id` should be displayed or not on the Member Portal.'
        end
      end
    end
  end
end