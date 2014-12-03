module MAPI
  module Models
    class MemberBalance
      include Swagger::Blocks
      swagger_model :MemberBalance do
        property :mortgages do
          key :type, :numeric
        end
        property :agency do
          key :type, :numeric
        end
        property :aaa do
          key :type, :numeric
        end
        property :aa do
          key :type, :numeric
        end
      end
    end
  end
end