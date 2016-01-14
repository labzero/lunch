Given(/^I don't see the (reports|resources|products) dropdown$/) do |dropdown|
  page.find('.logo').hover # make sure the mouse isn't left on top of the nav bar from a different test
  report_menu = page.find('.nav-menu', text: dropdown_title_regex(dropdown))
  report_menu.parent.assert_selector('.nav-dropdown', visible: :hidden)
end

When(/^I hover on the (products|reports|resources) link in the header$/) do |dropdown|
  page.find('.nav-menu', text: dropdown_title_regex(dropdown)).hover
end

Then(/^I should see the (reports|resources|products) dropdown$/) do |dropdown|
  report_menu = page.find('.nav-menu', text: dropdown_title_regex(dropdown))
  report_menu.parent.assert_selector('.nav-dropdown', visible: true)
end

When(/^I click on the (agreements|amortizing|arc|arc embedded|auction indexed|authorizations|callable|capital plan|collateral|choice libor|credit|fee schedules|forms|frc|frc embedded|guides|knockout|mortgage partnership finance|other cash needs|products summary|putable|reports|securities|securities backed credit|variable rate credit|membership|applications) link in the header$/) do |link|
  page.find('.page-header .secondary-nav a', text: dropdown_title_regex(link)).click
end

When(/^I click on the switch link in the nav$/) do
  page.find('.nav-member-switch a', text: I18n.t('nav.primary.switch')).click
end

Then(/^I should see the primary bank name in the header$/) do
  page.assert_selector('.header-member-name', text: CustomConfig.env_config['primary_bank'])
end

Then(/^I should see a datestamp in the navigation header$/) do
  page.assert_selector('nav time')
end

def dropdown_title_regex(dropdown)
  title = case dropdown
  when 'agreements'
    I18n.t('resources.forms.agreements.title')
  when 'amortizing'
    I18n.t('products.advances.amortizing.title')
  when 'arc'
    I18n.t('products.advances.arc.title')
  when 'arc embedded'
    I18n.t('products.advances.arc_embedded.title')
  when 'auction indexed'
    I18n.t('products.advances.auction_indexed.title')
  when 'authorizations'
    I18n.t('resources.forms.authorizations.title')
  when 'callable'
    I18n.t('products.advances.callable.title')
  when 'capital plan'
    I18n.t('resources.capital_plan.title')
  when 'choice libor'
    I18n.t('products.advances.choice_libor.title')
  when 'collateral'
    I18n.t('resources.forms.collateral.title')
  when 'credit'
    I18n.t('resources.forms.credit.title')
  when 'fee schedules'
    I18n.t('resources.fee_schedules.title')
  when 'forms'
    I18n.t('resources.forms.title')
  when 'frc'
    I18n.t('products.advances.frc.title')
  when 'frc embedded'
    I18n.t('products.advances.frc_embedded.title')
  when 'guides'
    I18n.t('resources.guides.title')
  when 'knockout'
    I18n.t('products.advances.knockout.title')
  when 'mortgage partnership finance'
    I18n.t('products.advances.mpf.title')
  when 'other cash needs'
    I18n.t('products.advances.ocn.title')
  when 'products'
    I18n.t('nav.secondary.products')
  when 'products summary'
    I18n.t('products.products_summary.nav_title')
  when 'putable'
    I18n.t('products.advances.putable.title')
  when 'reports'
    I18n.t('reports.title')
  when 'resources'
    I18n.t('nav.secondary.resources')
  when 'securities'
    I18n.t('securities.title')
  when 'securities backed credit'
    I18n.t('products.advances.sbc.title')
  when 'variable rate credit'
    I18n.t('products.advances.vrc.title')
  when 'membership'
    I18n.t('resources.membership.title')
  when 'applications'
    I18n.t('resources.membership.applications.nav_title')
  else
    raise 'unknown dropdown'
  end
  /\A#{Regexp.quote(title)}\z/
end
