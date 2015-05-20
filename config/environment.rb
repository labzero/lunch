# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

require 'securid_service' # rails autoloader has issues with this one due to its naming
