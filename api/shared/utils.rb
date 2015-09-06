module MAPI
  module Shared
    module Utils
      extend ActiveSupport::Concern

      module ClassMethods
        def hash_from_pairs(key_value_pairs)
          Hash[key_value_pairs].with_indifferent_access
        end
      end
    end
  end
end
