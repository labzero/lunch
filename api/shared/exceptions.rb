module MAPI
  module Shared
    module Errors
      class SQLError < StandardError; end

      class ValidationError < ArgumentError

        attr_reader :code, :value, :type

        def initialize(message, code=nil, value=nil)
          super(message)
          @code = code
          @value = value
          @type = :validation
        end

      end

      class MissingFieldError < ValidationError
        def initialize(message, code=nil, value=nil)
          super(message, code, value)
          @type = :blank
        end
      end

      class InvalidFieldError < ValidationError
        def initialize(message, code=nil, value=nil)
          super(message, code, value)
          @type = :invalid
        end
      end

      class CustomTypedFieldError < ValidationError
        def initialize(message, type, code=nil, value=nil)
          super(message, code, value)
          @type = type
        end
      end
    end
  end
end