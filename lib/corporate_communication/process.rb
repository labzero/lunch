require 'corporate_communication'

class CorporateCommunication
  module Process
    require 'nokogiri'
    require 'css_parser'
    require 'net/http'
    require 'uri'
    require 'net/imap'

    def self.process_email_html(email)
      html = (email.html_part || email).body.decoded

      doc = Nokogiri::HTML(html)
      style = doc.at('style')
      stylesheet = style.try(:content)
      parser = CssParser::Parser.new
      new_css = CssParser::Parser.new
      parser.add_block!(stylesheet) if stylesheet

      parser.each_rule_set do |rule_set|
        rule_set.each_selector do |selector|
          new_selector = '.corporate-communication-detail-reset ' + selector
          new_css.add_rule!(new_selector, parser.find_by_selector(selector).first)
        end
      end

      style.inner_html = new_css.to_s if style
      body = doc.at('body')
      body.xpath('//img[starts-with(@src, "http://open.mkt1700.com/open/log/")]').remove
      body.xpath('//p//span[contains(text(), "You are receiving this email as a test mailing")]').remove
      body.xpath('//center[//*[contains(text(), "This message contains graphics")]]').remove
      body.xpath('//tr[contains(comment(), "Read online link to silverpop")]').remove

      body.xpath('//a[starts-with(@href, "http://links.mkt1700.com/")]/@href').each do |link|
        uri = URI.parse(link)
        location = Net::HTTP.get_response(uri).header['location']
        if location
          link.content = location
        end
      end

      body.xpath('//area[starts-with(@href, "http://links.mkt1700.com/")]/@href').each do |link|
        uri = URI.parse(link)
        location = Net::HTTP.get_response(uri).header['location']
        if location
          link.content = location
        end
      end

      images = []
      body.xpath('//img/@src').each do |image_url|
        next if image_url.content =~ /\Acid:/
        image_details = process_email_image(image_url.content)
        image_url.content = "cid:#{image_details[:fingerprint]}"
        images << image_details
      end


      body.children.first.add_previous_sibling(style) if style

      {
        html: body.inner_html,
        images: images
      }
    end

    def self.process_email_image(image_url)
      uri = URI.parse(image_url)
      image = Net::HTTP.get_response(uri)
      digest = Digest::SHA2.new
      {
        fingerprint: (digest << image.body).to_s,
        data: Base64.encode64(image.body),
        content_type: image.content_type,
        name: File.basename(image_url.to_s)
      }
    end

    def self.process_email_attachments(email)
      email.attachments.collect { |attachment| process_email_attachment(attachment) }
    end

    def self.process_email_attachment(attachment)
      data = attachment.body.decoded
      digest = Digest::SHA2.new
      {
        fingerprint: (digest << data).to_s,
        data: Base64.encode64(data),
        name: attachment.filename,
        content_type: attachment.mime_type
      }
    end

    def self.process_email(email, category=nil)
      body_parts = process_email_html(email)
      attachments = process_email_attachments(email)
      { 
        body: body_parts[:html],
        images: body_parts[:images],
        attachments: attachments,
        email_id: email.message_id,
        title: email.subject,
        date: email.date,
        category: category
      }
    end

    def self.persist_attachments(corp_com, email)
      email = email.with_indifferent_access

      CorporateCommunication.transaction do
        [:attachments, :images].each do |association|
          new_fingerprints = (email[association] || []).collect { |attachment| attachment[:fingerprint] }
          attachments = corp_com.send(association)
          old_fingerprints = attachments.collect(&:fingerprint)
          attachments.each do |attachment|
            attachment.destroy unless new_fingerprints.include?(attachment.fingerprint)
          end
          (email[association] || []).each do |attachment|
            fingerprint = attachment[:fingerprint]
            unless old_fingerprints.include?(fingerprint)
              file = StringIOWithFilename.new(Base64.decode64(attachment[:data]))
              file.original_filename = attachment[:name]
              file.content_type = attachment[:content_type]
              attachments.build(data: file, fingerprint: fingerprint)
            end
          end      
        end

        corp_com.save!
      end
    end

    def self.persist_processed_email(email)
      email = email.with_indifferent_access
      corp_com = nil

      CorporateCommunication.transaction do
        corp_com = CorporateCommunication.find_or_initialize_by(email_id: email[:email_id])
        
        corp_com.date_sent = email[:date].to_datetime
        corp_com.title = email[:title]
        corp_com.body = email[:body]
        corp_com.category = email[:category]
        
        corp_com.save!

        persist_attachments(corp_com, email)
      end
      corp_com
    end

    def self.fetch_and_process_email(category, username=ENV['IMAP_USERNAME'], password=ENV['IMAP_PASSWORD'], host=ENV['IMAP_HOST'], port=ENV['IMAP_PORT'])
      ssl = port.to_i == 993
      result = false

      email_objects = []
      processed_emails = []

      begin
        options = {port: port}
        if ssl
          options[:ssl] = {verify_mode: OpenSSL::SSL::VERIFY_PEER}
          options[:ssl][:ca_file] = ENV['IMAP_CA_BUNDLE_PATH'] if ENV['IMAP_CA_BUNDLE_PATH']
        else
          options[:ssl] = nil
        end
        client = Net::IMAP.new(host, options)
        client.login(username, password)
        client.examine('INBOX')
        list = client.uid_search('UNSEEN')

        if list.present?
          emails = client.uid_fetch(list, 'RFC822')
          email_objects = Hash[*(emails.map { |email| [email.attr['UID'], Mail.read_from_string(email.attr['RFC822'])] }.flatten)]

          email_objects.each do |uid, email|
            Rails.logger.info { "Processing '#{email.subject}', category: #{category}..." }
            processed_email = process_email(email, category)
            if self.persist_processed_email(processed_email)
              processed_emails << uid
              Rails.logger.info { 'success' }
            else
              Rails.logger.info { 'failure' }
            end
          end

          client.select('INBOX')
          client.uid_store(processed_emails, '+FLAGS.SILENT', [:Seen, :Deleted])
          client.close
        end

        client.logout
        result = true
      rescue Net::IMAP::Error => error
        Rails.logger.info { "Fatal error: #{error}" }
        Rails.logger.debug { error.backtrace.try(:join, "\n") }
        result = false
      end

      if result
        Rails.logger.info { "Found #{email_objects.count} #{'email'.pluralize(email_objects.count)}." }
        Rails.logger.info { "Processed #{processed_emails.count} #{'email'.pluralize(processed_emails.count)} succesfully." }
      end

      result
    end
  end
end