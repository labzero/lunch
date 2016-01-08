if defined?(Savon)
  require 'new_relic/agent/datastores'
  require 'json'
  
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