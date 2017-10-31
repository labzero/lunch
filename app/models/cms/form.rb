class Cms::Form < Cms::BaseObject
  def form_page_title
    @form_page_title ||= cms.get_attribute_as_text(cms_key, 'forms-page-name')
  end
end