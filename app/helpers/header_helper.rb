module HeaderHelper

  def header_report_nav_item(title, path, enabled=true)
    content = enabled ? link_to(title, path) : title
    content_tag(:li, content, class: enabled ? nil : :disabled)
  end

end