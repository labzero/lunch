Then(/^I should see the "(.*?)" product page$/) do |product|
  text = case product
    when 'products summary'
      I18n.t('products.products_summary.title')
    when 'arc embedded'
      I18n.t('products.advances.arc_embedded.title')
    when 'amortizing'
      I18n.t('products.advances.amortizing.title')
    when 'auction indexed'
      I18n.t('products.advances.auction_indexed.title')
    when 'frc'
      I18n.t('products.advances.frc.title')
    when 'frc embedded'
      I18n.t('products.advances.frc_embedded.title')
    when 'arc'
      I18n.t('products.advances.arc.title')
    when 'choice libor'
      I18n.t('products.advances.choice_libor.title')
    when 'knockout'
      I18n.t('products.advances.knockout.title')
    when 'other cash needs'
      I18n.t('products.advances.ocn.title')
    when 'putable'
      I18n.t('products.advances.putable.title')
    when 'callable'
      I18n.t('products.advances.callable.title')
    when 'variable rate credit'
      I18n.t('products.advances.vrc.title')
    when 'securities backed credit'
      I18n.t('products.advances.sbc.title')
    when 'mortgage partnership finance'
      I18n.t('products.advances.mpf.title')
    else
      raise 'unknown product page'
  end
  page.assert_selector('.product-page h1', text: text)
end

Then(/^I should see the pfi page$/) do
  page.assert_selector('.product-mpf-page h1 span', text: I18n.t('products.advances.pfi.title'))
end

When(/^I click on the (arc embedded|frc|frc embedded|arc|amortizing|choice libor|auction indexed|knockout|putable|other cash needs|mortgage partnership finance) link in the products advances dropdown$/) do |link|
  page.find('.page-header .products-dropdown .nav-dropdown-nested a', text: dropdown_title_regex(link)).click
end

When(/^I click on the pfi link$/) do
  click_link('PFI Application')
end

Then(/^I should see at least one pfi form to download$/) do
  page.assert_selector('.product-mpf-table a', text: /\A#{Regexp.quote(I18n.t('global.view_pdf'))}\z/i, minimum: 1)
end

Given(/^I am on the pfi page$/) do
  visit '/products/advances/pfi'
end

