require 'rubygems'
require 'bundler'

Bundler.require

require './api_mock'
run Rack::URLMap.new("/" => APIDocs, "/rates" => APIMockRates,  "/members" => APIMockMembers)
