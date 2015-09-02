Given(/^I don't see the (reports|resources|products) dropdown$/) do |dropdown|
  page.find('.logo').hover # make sure the mouse isn't left on top of the nav bar from a different test
  report_menu = page.find('.nav-menu', text: dropdown_title_regex(dropdown))
  report_menu.parent.assert_selector('.nav-dropdown', visible: :hidden)
end

When(/^I hover on the (reports|resources|products) link in the header$/) do |dropdown|
  page.find('.nav-menu', text: dropdown_title_regex(dropdown)).hover
end

Then(/^I should see the (reports|resources|products) dropdown$/) do |dropdown|
  report_menu = page.find('.nav-menu', text: dropdown_title_regex(dropdown))
  report_menu.parent.assert_selector('.nav-dropdown', visible: true)
end

When(/^I click on the (reports|guides|forms|agreements|authorizations|credit|collateral|products summary|arc embedded|frc|frc embedded|arc|amortizing|choice libor|auction indexed|knockout|other cash needs|putable) link in the header$/) do |link|
  page.find('.page-header .secondary-nav a', text: dropdown_title_regex(link)).click
end

Then(/^I should see the primary bank name in the header$/) do
  page.assert_selector('.header-member-name', text: CustomConfig.env_config['primary_bank'])
end

def dropdown_title_regex(dropdown)
  title = case dropdown
  when 'reports'
    I18n.t('reports.title')
  when 'resources'
    I18n.t('nav.secondary.resources')
  when 'guides'
    I18n.t('resources.guides.title')
  when 'forms'
    I18n.t('resources.forms.title')
  when 'agreements'
    I18n.t('resources.forms.agreements.title')
  when 'authorizations'
    I18n.t('resources.forms.authorizations.title')
  when 'credit'
    I18n.t('resources.forms.credit.title')
  when 'collateral'
    I18n.t('resources.forms.collateral.title')
  when 'products'
    I18n.t('nav.secondary.products')
  when 'products summary'
    I18n.t('products.products_summary.nav_title')
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
  when 'putable'
    I18n.t('products.advances.putable.title')
  else
    raise 'unknown dropdown'
  end
  /\A#{Regexp.quote(title)}\z/
end
