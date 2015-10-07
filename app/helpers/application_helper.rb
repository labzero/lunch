module ApplicationHelper
  def disabled_link_to(*args)
    name = block_given? ? yield : args.first
     "<span class='disabled_link'>#{name}</span>".html_safe
  end
end
