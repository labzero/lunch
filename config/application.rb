require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FhlbMember
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.time_zone = ENV['TIMEZONE'] || 'Pacific Time (US & Canada)'

    config.mapi = ActiveSupport::OrderedOptions.new
    config.mapi.endpoint = ENV['MAPI_ENDPOINT'] || 'http://localhost:3100/mapi'

    # moved the session parser up in the middleware hierarchy
    config.middleware.delete(ActionDispatch::Cookies)
    config.middleware.delete(ActionDispatch::Session::CookieStore)
    config.middleware.insert_before(Rails::Rack::Logger, ActionDispatch::Session::CookieStore)
    config.middleware.insert_before(ActionDispatch::Session::CookieStore, ActionDispatch::Cookies)

    config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
    config.log_tags = [
      lambda { |request| "request_id=#{request.uuid}" },
      lambda { |request| "session_id=#{request.session.id}"},
      lambda { |request| request.session["warden.user.user.key"].nil? ? "user_id=NONE" : "user_id=#{request.session["warden.user.user.key"][0][0]}"}
    ]
    config.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(Rails.root.join('log', "#{Rails.env}.log"), 'daily'))
    config.active_job.queue_adapter = :resque

    config.active_record.raise_in_transactional_callbacks = true
  end
end
