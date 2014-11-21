require 'rubygems'
require 'bundler'

Bundler.setup # don't auto require all gems

require_relative 'mapi'
run Rack::URLMap.new("/" => MAPI::DocApp, "/mapi" => MAPI::ServiceApp)
