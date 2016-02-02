module Constraints
  class FeatureEnabled
    include FlipperHelper
    attr_reader :feature
    REQUEST_KEY = 'constraints.feature_enabled.request'

    def initialize(feature)
      @feature = feature
    end

    def current_member_id
      (Thread.current[REQUEST_KEY].try(:session) || {})['member_id']
    end

    def matches?(request)
      current_user = request.env['warden'].user
      with_request(request) do
        feature_enabled?(feature, current_user)
      end
    end

    protected

    def with_request(request)
      begin
        old_request = Thread.current[REQUEST_KEY]
        Thread.current[REQUEST_KEY] = request
        yield
      ensure
        Thread.current[REQUEST_KEY] = old_request
      end
    end

  end
end