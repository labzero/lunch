if defined?(NewRelic::Agent)
  require 'new_relic/agent/datastores'
  require 'json'

  if defined?(Net::LDAP)
    [
      :add, :bind, :bind_as, :delete, :get_operation_result, :modify, :open,
      :rename
    ].each do |method|
      NewRelic::Agent::Datastores.trace(Net::LDAP, method, 'LDAP')
    end

    class Net::LDAP

      def search_with_newrelic(*args, &block)
        callback = Proc.new do |result, metrics, elapsed|
          query = args.first
          if query
            query_string = JSON.dump({
              base: query[:base].try(:to_s),
              filter: query[:filter].try(:to_s),
              attributes: query[:attributes].try(:to_s),
              scope: query[:scope].try(:to_s)
            })
            NewRelic::Agent::Datastores.notice_statement(query_string, elapsed)
          end
        end
        NewRelic::Agent::Datastores.wrap('LDAP', :search, host, callback) do
          search_without_newrelic(*args, &block)
        end
      end

      alias_method_chain :search, :newrelic

    end
  end

  if defined?(Savon)
    class Savon::Client

      def call_with_newrelic(*args, &block)
        operation = args.first
        payload = args.second
        callback = Proc.new do |result, metrics, elapsed|
          if payload
            query_string = JSON.dump(payload)
            query_string.gsub!(ENV['SOAP_SECRET_KEY'], '*****') # mask our password
            NewRelic::Agent::Datastores.notice_statement(query_string, elapsed)
          end
        end
        NewRelic::Agent::Datastores.wrap('SOAP', :call, "#{service_name}##{operation}", callback) do
          call_without_newrelic(*args, &block)
        end
      end

      alias_method_chain :call, :newrelic

    end
  end
end