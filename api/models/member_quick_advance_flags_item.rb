
module MAPI
  module Models
    class MemberQuickAdvanceFlagsItem
      include Swagger::Blocks
      swagger_model :MemberQuickAdvanceFlagsItem do
        key :required, %i(fhlb_id member_name quick_advance_enabled)
        property :fhlb_id do
          key :type, :integer
          key :description, 'The FHLB_ID of the member institution'
        end
        property :member_name do
          key :type, :string
          key :description, 'The member institution name'
        end
        property :quick_advance_enabled do
          key :type, :boolean
          key :description, 'Whether or not quick advance is enabled for this member institution'
        end
      end
    end
  end
end