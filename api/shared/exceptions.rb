module MAPI
  module Shared
    module Errors
      class SQLError < StandardError; end

      class ValidationError < ArgumentError

        attr_reader :code

        def initialize(message, code=nil)
          super(message)
          @code = code
        end

      end
    end
  end
end