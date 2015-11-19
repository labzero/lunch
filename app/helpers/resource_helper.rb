module ResourceHelper
  def link_to_download_resource(text, download_url, options={})
    options.reverse_merge!(target: '_blank')
    link_to(text, download_url, options)
  end
end