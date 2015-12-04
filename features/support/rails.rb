if defined?(ActionController)
  ActionController::Base.class_eval do
    cattr_accessor :allow_rescue
  end

  class ActionDispatch::ShowExceptions
    def call_with_rescue(env)
      env['action_dispatch.show_exceptions'] = !!ActionController::Base.allow_rescue
      call_without_rescue(env)
    end

    alias_method_chain :call, :rescue
  end

  Around('@allow-rescue') do |scenario, block|
    begin
      allowed = ActionController::Base.allow_rescue
      ActionController::Base.allow_rescue = true
      block.call
    rescue Exception => e
      raise e
    ensure
      ActionController::Base.allow_rescue = allowed
    end
  end
end