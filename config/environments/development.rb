Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Paperclip storage configuration
  config.paperclip_defaults = {
      path: File.join(Rails.root, 'tmp', 'paperclip', ':class', ':attachment', ':id_partition', ':style', ':filename')
  }

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  # config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  config.action_view.raise_on_missing_translations = true

  config.action_mailer.delivery_method = ENV['LOCAL_MAIL'] == 'true' ? :letter_opener : false
  config.action_mailer.asset_host = "http://localhost:#{ENV['PORT']}"
end

if ENV['DEBUG'] == 'true'
  require 'byebug'
  require 'byebug/core'
  
  def find_available_port
    server = TCPServer.new(nil, 0)
    server.addr[1]
  ensure
    server.try(:close)
  end

  port = ENV['BYEBUG_PORT'] || find_available_port
  puts "Remote debugger on port #{port}"
  Byebug.start_server 'localhost', port
  Byebug::Breakpoint.add(ENV['BYEBUG_FILE'], ENV['BYEBUG_LINE'].to_i) if ENV['BYEBUG_FILE'] && ENV['BYEBUG_LINE']
end
