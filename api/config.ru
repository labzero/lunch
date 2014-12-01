require 'rubygems'
require 'bundler'

Bundler.setup # don't auto require all gems

require 'dotenv'
Dotenv.load '../.env'

require_relative 'mapi'
run Rack::URLMap.new("/" => MAPI::DocApp, "/mapi" => MAPI::ServiceApp, "/healthy" => MAPI::HealthApp)
