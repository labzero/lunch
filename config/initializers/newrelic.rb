if defined?(NewRelic::Agent)
  require 'new_relic/agent/datastores'

  if defined?(Net::LDAP)
    class Net::LDAP
      include ::NewRelic::Agent::MethodTracer

      [
        :add, :bind, :bind_as, :delete, :get_operation_result, :modify, :open,
        :rename, :search
      ].each do |method|
        add_method_tracer method
      end
    end
  end

  if defined?(Savon)
    class Savon::Client

      def call_with_newrelic(*args, &block)
        operation = args.first
        message = args.second
        callback = Proc.new do |result, metrics, elapsed|
          NewRelic::Agent::Datastores.notice_statement(message.to_json, elapsed) if message
        end
        NewRelic::Agent::Datastores.wrap('SOAP', :call, "#{service_name}###{operation}", callback) do
          call_without_newrelic(*args, &block)
        end
      end

      alias_method_chain :call, :newrelic

    end
  end
end