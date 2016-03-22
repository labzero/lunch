module FhlbMember
  class WardenProxy
    # Simulates a Warden::Proxy object for situations when we need to use Devise-based
    # controllers w/o a real request or middleware stack.

    def initialize(authenticated_as)
      @authenticated_as = authenticated_as
    end

    def authenticate!(*args)
      authenticate(*args)
    end

    def authenticate(*args)
      @authenticated_as
    end

    def authenticate?(*args)
      result = !!authenticate(*args)
      yield if block_given? && result
      result
    end

    def authenticated?(*args, &block)
      authenticate?(*args, &block)
    end

    def unauthenticated?(*args, &block)
      !authenticate?(*args, &block)
    end
  end
end