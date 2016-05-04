module CacheConfiguration
  NAMESPACE = 'cache'.freeze
  SEPARATOR = ':'.freeze
  CONFIG = {
    member_contacts: {
      key_prefix: 'contacts',
      expiry: 24.hours
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