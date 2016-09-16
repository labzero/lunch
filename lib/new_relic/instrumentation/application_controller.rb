NewRelic::Agent.logger.info('Installing ApplicationController handled error instrumentation')
ActiveSupport.on_load(:class_application_controller) do |*args|
  ApplicationController.class_eval do
    unless method_defined?(:handle_exception_with_newrelic)
      NewRelic::Agent.logger.info('Adding ApplicationController hooks')
      def handle_exception_with_newrelic(*args, &block)
        exception = args.first
        options = {}
        if request
          options[:uri] = request.path
          options[:referrer] = request.referrer
        end
        NewRelic::Agent.notice_error(exception, options)
        handle_exception_without_newrelic(*args, &block)
      end

      alias_method_chain :handle_exception, :newrelic
    end
  end
end