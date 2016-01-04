if defined?(NewRelic::Agent)
  require 'new_relic/agent/datastores'
  require 'json'

  if defined?(Net::LDAP)
    [
      :bind_as, :get_operation_result, :open
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
            NewRelic::Agent::Datastores.notice_statement("search: #{query_string}", elapsed)
          end
        end
        NewRelic::Agent::Datastores.wrap('LDAP', :search, host, callback) do
          search_without_newrelic(*args, &block)
        end
      end

      def add_with_newrelic(*args, &block)
        callback = Proc.new do |result, metrics, elapsed|
          query = args.first
          if query
            query_string = JSON.dump({
              dn: query[:dn].try(:to_s),
              attributes: query[:attributes].try(:inject, {}) { |hash, (key, value)| hash[key] = '*'; hash }
            })
            NewRelic::Agent::Datastores.notice_statement("add: #{query_string}", elapsed)
          end
        end
        NewRelic::Agent::Datastores.wrap('LDAP', :add, host, callback) do
          add_without_newrelic(*args, &block)
        end
      end

      def delete_with_newrelic(*args, &block)
        callback = Proc.new do |result, metrics, elapsed|
          query = args.first
          if query
            query_string = JSON.dump(query_string)
            NewRelic::Agent::Datastores.notice_statement("delete: #{query_string}", elapsed)
          end
        end
        NewRelic::Agent::Datastores.wrap('LDAP', :delete, host, callback) do
          delete_without_newrelic(*args, &block)
        end
      end

      def rename_with_newrelic(*args, &block)
        callback = Proc.new do |result, metrics, elapsed|
          query = args.first
          if query
            query_string = JSON.dump(query_string)
            NewRelic::Agent::Datastores.notice_statement("rename: #{query_string}", elapsed)
          end
        end
        NewRelic::Agent::Datastores.wrap('LDAP', :rename, host, callback) do
          rename_without_newrelic(*args, &block)
        end
      end

      def modify_with_newrelic(*args, &block)
        callback = Proc.new do |result, metrics, elapsed|
          query = args.first
          if query
            query_string = JSON.dump({
              dn: query[:dn].try(:to_s),
              operations: query[:operations].try(:collect) { |op| [op.first, op.second, '*'] }
            })
            NewRelic::Agent::Datastores.notice_statement("modify: #{query_string}", elapsed)
          end
        end
        NewRelic::Agent::Datastores.wrap('LDAP', :modify, host, callback) do
          modify_without_newrelic(*args, &block)
        end
      end

      def bind_with_newrelic(*args, &block)
        callback = Proc.new do |result, metrics, elapsed|
          query = args.first || @auth
          if query
            query_string = JSON.dump({
              method: query[:method].try(:to_s),
              username: query[:username].try(:to_s),
              password: query[:password] ? '*' : nil
            })
            NewRelic::Agent::Datastores.notice_statement("bind: #{query_string}", elapsed)
          end
        end
        NewRelic::Agent::Datastores.wrap('LDAP', :bind, host, callback) do
          bind_without_newrelic(*args, &block)
        end
      end

      alias_method_chain :search, :newrelic
      alias_method_chain :add, :newrelic
      alias_method_chain :delete, :newrelic
      alias_method_chain :rename, :newrelic
      alias_method_chain :modify, :newrelic
      alias_method_chain :bind, :newrelic

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
            query_string.gsub!(ENV['SOAP_SECRET_KEY'], '*****') if ENV['SOAP_SECRET_KEY'] # mask our password
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