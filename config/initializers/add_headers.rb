module Rack
  class AddResponseHeaders
    def initialize(app, options={})
      @app = app
      @options = options
    end

    def call(env)
      status, headers, body = @app.call(env)
      @options.each do |key, val|
        headers[key] = val
      end

      [status, headers, body]
    end
  end
end

Rails.application.config.middleware.use(Rack::AddResponseHeaders, {'X-Frame-Options' => 'SAMEORIGIN'})