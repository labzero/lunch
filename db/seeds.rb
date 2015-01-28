# Corporate Communications Seeds
messages = JSON.parse(File.read(File.join(Rails.root, 'db', 'corporate_communications.json')))
existing_email_ids = CorporateCommunication.pluck(:email_id)
messages.each_with_index do |message, index|
  break if existing_email_ids.include?(message['email_id'])
  corp_com = CorporateCommunication.new
  corp_com.date_sent = message['date'].to_datetime
  corp_com.title = message['title']
  corp_com.body = message['body']
  corp_com.category = message['category']
  corp_com.email_id = message['email_id']
  corp_com.save!
end
