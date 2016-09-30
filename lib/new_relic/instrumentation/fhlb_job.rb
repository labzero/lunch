NewRelic::Agent.logger.info('Installing FhlbJob instrumentation')
ActiveSupport.on_load(:class_fhlb_job) do |*args|
  FhlbJob.class_eval do
    unless method_defined?(:handle_exception_with_newrelic)
      NewRelic::Agent.logger.info('Adding FhlbJob hooks')
      def handle_exception_with_newrelic(*args, &block)
        exception = args.first
        options = {job_id: job_id, job_class: self.class.name}
        NewRelic::Agent.notice_error(exception, options)
        handle_exception_without_newrelic(*args, &block)
      end

      alias_method_chain :handle_exception, :newrelic
    end
  end
end
