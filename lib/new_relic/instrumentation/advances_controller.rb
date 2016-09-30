NewRelic::Agent.logger.info('Installing AdvancesController handled error instrumentation')
ActiveSupport.on_load(:"method_advances_controller.handle_advance_exception") do
  AdvancesController.class_eval do
    unless method_defined?(:handle_advance_exception_with_newrelic)
      NewRelic::Agent.logger.info('Adding AdvancesController hooks')
      def handle_advance_exception_with_newrelic(*args, &block)
        exception = args.first
        options = {}
        if request
          options[:uri] = request.path
          options[:referrer] = request.referrer
        end
        if advance_request
          options[:advance] = advance_request.to_json
        end
        NewRelic::Agent.notice_error(exception, options)
        handle_advance_exception_without_newrelic(*args, &block)
      end

      alias_method_chain :handle_advance_exception, :newrelic
    end
  end
end
