# Corporate Communications Seeds
messages = JSON.parse(File.read(File.join(Rails.root, 'db', 'corporate_communications.json')))
existing_email_ids = CorporateCommunication.pluck(:email_id)
messages.each_with_index do |message, index|
  CorporateCommunication.transaction do
    if existing_email_ids.include?(message['email_id'])
      corp_com = CorporateCommunication.where(email_id: message['email_id']).first
    else
      corp_com = CorporateCommunication.new
    end
    
    corp_com.date_sent = message['date'].to_datetime
    corp_com.title = message['title']
    corp_com.body = message['body']
    corp_com.category = message['category']
    corp_com.email_id = message['email_id']
    
    corp_com.save! if corp_com.new_record? # work around rails ploymorphic save issue

    ['attachments', 'images'].each do |association|
      new_fingerprints = (message[association] || []).collect { |attachment| attachment['fingerprint'] }
      attachments = corp_com.send(association)
      old_fingerprints = attachments.collect(&:fingerprint)
      attachments.each do |attachment|
        attachment.destroy unless new_fingerprints.include?(attachment.fingerprint)
      end
      (message[association] || []).each do |attachment|
        fingerprint = attachment['fingerprint']
        unless old_fingerprints.include?(fingerprint)
          file = StringIOWithFilename.new(Base64.decode64(attachment['data']))
          file.original_filename = attachment['name']
          file.content_type = attachment['content_type']
          attachments.build(data: file, fingerprint: fingerprint)
        end
      end      
    end

    corp_com.save!
  end
end
