require 'rubygems'
require 'bundler'

Bundler.setup # don't auto require all gems

require 'dotenv'
Dotenv.load '../.env'

ENV['RACK_ENV'] = ENV['RAILS_ENV'] if !ENV['RACK_ENV'] && ENV['RAILS_ENV']

require_relative 'mapi'
run Rack::URLMap.new("/" => MAPI::DocApp, "/mapi" => MAPI::ServiceApp, "/healthy" => MAPI::HealthApp)
