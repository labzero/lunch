Then(/^I should see the "(.*?)" product page$/) do |product|
  text = case product
    when 'products summary'
      I18n.t('products.products_summary.title')
    when 'frc'
      I18n.t('products.advances.frc.title')
    when 'frc embedded'
      I18n.t('products.advances.frc_embedded.title')
    else
      raise 'unknown product page'
  end
  page.assert_selector('.product-page h1', text: text)
end



