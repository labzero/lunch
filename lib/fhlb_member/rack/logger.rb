# Behaves just like Rails::Rack:Logger but logs the `remote_ip` instead of the `ip`.
module FhlbMember
  module Rack
    class Logger < Rails::Rack::Logger
      protected
      def started_request_message(request)
        'Started %s "%s" for %s at %s' % [
          request.request_method,
          request.filtered_path,
          request.remote_ip,
          Time.now.to_default_s ]
      end
    end
  end
end
