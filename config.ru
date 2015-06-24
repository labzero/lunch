# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

if ENV['PROFILE_MODE']
  use *Profiler.middleware('rails_profile')
end

run Rails.application
