module ProcessCorpCom
  require 'nokogiri'
  require 'css_parser'
  require 'net/http'
  require 'uri'

  def self.prepend_style_tags(file_location)
    file_location = File.expand_path(file_location)
    original_email = Mail.read(file_location)
    html = original_email.html_part.body.decoded

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


    body.children.first.add_previous_sibling(style)

    body.inner_html.gsub("\n", '\n').gsub("\"", '\"')

  end

end