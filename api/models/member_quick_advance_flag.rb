module MAPI
  module Models
    class MemberQuickAdvanceFlag
      include Swagger::Blocks
      swagger_model :MemberQuickAdvanceFlag do
        property :quick_advance_enabled do
          key :type, :boolean
          key :required, true
          key :description, 'A boolean indicating whether or not quick advances are enabled for a given member'
        end
      end
    end
  end
end