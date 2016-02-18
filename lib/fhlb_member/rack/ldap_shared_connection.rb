module FhlbMember
  module Rack
    class LDAPSharedConnection
      def initialize(app)
        @app = app
      end

      def call(env)
        Devise::LDAP::Adapter.shared_connection do
          @app.call env
        end
      end
    end
  end
end