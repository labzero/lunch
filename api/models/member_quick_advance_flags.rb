
module MAPI
  module Models
    class MemberQuickAdvanceFlags
      include Swagger::Blocks
      swagger_model :MemberQuickAdvanceFlags do
        key :required, [:flags]
        property :flags do
          key :type, :array
          key :description, 'An array of `MemberQuickAdvanceFlag` objects.'
          items do
            key :'$ref', :MemberQuickAdvanceFlag
          end
        end
      end
    end
  end
end