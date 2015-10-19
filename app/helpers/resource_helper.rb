module ResourceHelper
  def link_to_download_resource(text, download_url, target='_blank')
    link_to(text, download_url, target: target)     
  end
end