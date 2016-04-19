module Constraints
  class FeatureDisabled <Constraints::FeatureEnabled
    def matches?(request)
      !super
    end
  end
end