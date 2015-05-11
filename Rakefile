# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

ENV['RAILS_ENV'] ||= 'development' # work around for https://github.com/nevans/resque-pool/issues/113

require File.expand_path('../config/application', __FILE__)
require 'resque/tasks'

Rails.application.load_tasks
