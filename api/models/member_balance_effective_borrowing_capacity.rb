module MAPI
  module Models
    class MemberBalanceBorrowingCapacity
      include Swagger::Blocks
      swagger_model :MemberBalanceBorrowingCapacity do
        property :total_capacity do
          key :type, :integer
        end
        property :unused_capacity do
          key :type, :integer
        end
      end
    end
  end
end
