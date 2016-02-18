module Constraints
  class WebAdmin

    def matches?(request)
      current_user = request.env['warden'].user
      WebAdminPolicy.new(current_user, request).show?
    end

  end
end