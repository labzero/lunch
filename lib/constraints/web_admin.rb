module Constraints
  class WebAdmin

    attr_reader :query

    def initialize(query=:show?)
      @query = query.to_sym
    end

    def matches?(request)
      current_user = request.env['warden'].user
      WebAdminPolicy.new(current_user, request).public_send(@query)
    end

  end
end