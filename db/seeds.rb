# Corporate Communications Seeds

require 'corporate_communication/process'

messages = JSON.parse(File.read(File.join(Rails.root, 'db', 'corporate_communications.json')))
messages.each do |message|
  exit(1) unless CorporateCommunication::Process.persist_processed_email(message)
end
