module ProcessCorpCom
  require 'nokogiri'
  require 'css_parser'
  require 'net/http'
  require 'uri'

  def self.process_email_html(email)
    html = email.html_part.body.decoded

    doc = Nokogiri::HTML(html)
    stylesheet = doc.at('style').content
    parser = CssParser::Parser.new
    new_css = CssParser::Parser.new
    parser.add_block!(stylesheet)

    parser.each_rule_set do |rule_set|
      rule_set.each_selector do |selector|
        new_selector = '.corporate-communication-detail-reset ' + selector
        new_css.add_rule!(new_selector, parser.find_by_selector(selector).first)
      end
    end

    doc.at('style').inner_html = new_css.to_s
    style = doc.at('style')
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
      image_details = process_email_image(image_url)
      image_url.content = "cid:#{image_details[:fingerprint]}"
      images << image_details
    end


    body.children.first.add_previous_sibling(style)

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

  def self.process_email(file_location, category=nil)
    email = Mail.read(File.expand_path(file_location))

    body_parts = ProcessCorpCom.process_email_html(email)
    attachments = ProcessCorpCom.process_email_attachments(email)
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

end