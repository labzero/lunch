class Cms::Product < Cms::BaseObject
  def name
    @name ||= cms.get_attribute_as_text(cms_key, 'product-page-name')
  end

  def product_page_html
    @product_page_html ||= cms.get_attribute_as_html(cms_key, 'product-page-body')
  end
end