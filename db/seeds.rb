# Corporate Communications Seeds

require 'corporate_communication/process'

messages = JSON.parse(File.read(Rails.root.join('db', 'corporate_communications.json')))
messages.each do |message|
  exit(1) unless CorporateCommunication::Process.persist_processed_email(message)
end

if Rails.env.test?
  messages = JSON.parse(File.read(Rails.root.join('db', 'corporate_communications_test.json')))
  messages.each do |message|
    exit(1) unless CorporateCommunication::Process.persist_processed_email(message)
  end
end

CorporateCommunication.where('(created_at IS NULL OR created_at <= ?) AND date_sent <= ?', Date.new(2016,6,20), Date.new(2016,6,20)).each(&:destroy)

# Feature Flipper Seeds

Rails.application.load_tasks unless defined?(Rake) && Rake::Task['flipper:seed']
Rake::Task['flipper:seed'].invoke