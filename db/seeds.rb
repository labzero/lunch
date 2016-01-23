# Corporate Communications Seeds

require 'corporate_communication/process'

messages = JSON.parse(File.read(Rails.root.join('db', 'corporate_communications.json')))
messages.each do |message|
  exit(1) unless CorporateCommunication::Process.persist_processed_email(message)
end

# Feature Flipper Seeds

Rails.application.load_tasks unless defined?(Rake) && Rake::Task['flipper:seed']
Rake::Task['flipper:seed'].invoke