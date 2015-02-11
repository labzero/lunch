module ProcessCorpCom
  require 'nokogiri'
  require 'css_parser'

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
    body.children.first.add_previous_sibling(style)

    body.inner_html

  end


end