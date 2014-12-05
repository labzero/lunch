module MAPI
  module Models
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
