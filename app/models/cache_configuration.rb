unless defined?(CacheConfiguration)
  module CacheConfiguration
    NAMESPACE = 'cache'.freeze
    SEPARATOR = ':'.freeze
    CONFIG = {
      member_contacts: {
        key_prefix: 'contacts',
        expiry: 24.hours
      },
      user_metadata: {
        key_prefix: "users#{SEPARATOR}ldap#{SEPARATOR}metadata",
        expiry: 24.hours
      },
      user_roles: {
        key_prefix: "users#{SEPARATOR}ldap#{SEPARATOR}roles",
        expiry: 24.hours
      },
      user_groups: {
        key_prefix: "users#{SEPARATOR}ldap#{SEPARATOR}groups",
        expiry: 24.hours
      },
      overnight_vrc: {
        key_prefix: "rates#{SEPARATOR}overnight#{SEPARATOR}vrc",
        expiry: 30.seconds
      },
      default: {
        key_prefix: 'default',
        expiry: 24.hours
      }
    }.freeze
    
    def self.key(context, *key_variables)
      [config(context)[:key_prefix], *key_variables].join(SEPARATOR)
    end

    def self.expiry(context)
      config(context)[:expiry]
    end

    def self.config(context)
      CONFIG.has_key?(context) ? CONFIG[context] : CONFIG[:default]
    end
  end
end