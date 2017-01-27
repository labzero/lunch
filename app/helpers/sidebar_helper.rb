module SidebarHelper
  def content_with_sidebar(sidebars=[], &main_content)
    sidebars = Array.wrap(sidebars)
    sidebar_html = sidebars.collect do |sidebar_def|
      capture do
        render partial: "sidebars/#{sidebar_def[:name]}", locals: sidebar_def[:locals]
      end
    end.join('').html_safe
    content_tag(:div, class: 'column-9x3-left', &main_content) + content_tag(:div, sidebar_html, class: 'column-9x3-right')
  end
end