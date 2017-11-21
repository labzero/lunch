class Cms::Form < Cms::BaseObject
  def form_page_title
    @form_page_title ||= cms.get_attribute_as_text(cms_key, 'forms-page-name')
  end

  def application_page_title
    @application_page_title ||= cms.get_attribute_as_text(cms_key, 'application-page-name')
  end

  def description
    @description ||= cms.get_attribute_as_html(cms_key, 'description')
  end
end