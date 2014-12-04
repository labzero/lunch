module MAPI
  module Models
    class MemberBalanceTotalSecurities
      include Swagger::Blocks
      swagger_model :MemberBalanceTotalSecurities do
        property :pledge_securities do
          key :type, :integer
        end
        property :safekept_securities do
          key :type, :integer
        end
      end
    end
  end
end