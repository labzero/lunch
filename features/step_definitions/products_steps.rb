Then(/^I should see the "(.*?)" product page$/) do |product|
  text = case product
    when 'products summary'
      I18n.t('products.products_summary.title')
    when 'amortizing'
      I18n.t('products.advances.amortizing.title')
    when 'frc'
      I18n.t('products.advances.frc.title')
    when 'frc embedded'
      I18n.t('products.advances.frc_embedded.title')
    when 'arc'
      I18n.t('products.advances.arc.title')
    when 'choice libor'
      I18n.t('products.advances.choice_libor.title')
    else
      raise 'unknown product page'
  end
  page.assert_selector('.product-page h1', text: text)
end
