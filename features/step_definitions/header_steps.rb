Given(/^I don't see the (reports|resources|products|securities) dropdown$/) do |dropdown|
  page.find('.logo').hover # make sure the mouse isn't left on top of the nav bar from a different test
  report_menu = page.find('.nav-menu', text: dropdown_title_regex(dropdown))
  report_menu.find(:xpath, '..').assert_selector('.nav-dropdown', visible: :hidden)
end

Then(/^I should see the (reports|resources|products|securities) dropdown$/) do |dropdown|
  report_menu = page.find('.nav-menu', text: dropdown_title_regex(dropdown))
  report_menu.find(:xpath, '..').assert_selector('.nav-dropdown', visible: true)
end

When(/^I click on the (agreements|amortizing|arc|arc embedded|authorizations|callable|capital plan|collateral|choice libor|credit|fee schedules|forms|frc|frc embedded|guides|knockout|mortgage partnership finance|other cash needs|products summary|putable|reports|securities|securities backed credit|variable rate credit|membership|applications|manage advances|add advance|manage securities|securities requests|resources|products|learn more|securities|safekeep new|pledge new|letters of credit|manage letters of credit|test features|features|new letter of credit|convertible|standby letters of credit|trade credit rules|term rules|add advance availability|end of day shutoff) link in the header$/) do |link|
  page.find('.page-header .secondary-nav a', text: dropdown_title_regex(link)).click
end

When(/^I click on the switch link in the nav$/) do
  page.find('.nav-member-switch a', text: I18n.t('nav.primary.switch')).click
end

Then(/^I should see the primary bank name in the header$/) do
  page.assert_selector('.header-member-name', text: CustomConfig.env_config['primary_user']['bank'])
end

Then(/^I should see a datestamp in the navigation header$/) do
  page.assert_selector('nav time')
end

Then(/^I should see the active state of the (securities|advances|reports|products|resources) nav item$/) do |nav_item|
  translation = case nav_item
  when 'securities'
    'securities.title'
  when 'advances'
    'nav.secondary.advances'
  when 'reports'
    'reports.title'
  when 'products'
    'nav.secondary.products'
  when 'resources'
    'nav.secondary.resources'
  end
  page.assert_selector('.active-nav-item a', text: I18n.t(translation), exact: true)
end

def dropdown_title_regex(dropdown)
  title = case dropdown
  when 'advances'
    I18n.t('nav.secondary.advances')
  when 'agreements'
    I18n.t('resources.forms.agreements.title')
  when 'amortizing'
    I18n.t('products.advances.amortizing.title')
  when 'arc'
    I18n.t('products.advances.arc.title')
  when 'arc embedded'
    I18n.t('products.advances.arc_embedded.title')
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
  when 'manage advances'
    I18n.t('advances.manage_advances.title')
  when 'mortgage partnership finance'
    I18n.t('products.advances.mpf.title')
  when 'add advance'
    I18n.t('advances.add_advance.nav')
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
  when 'manage securities'
    I18n.t('securities.manage.title')
  when 'securities requests'
    I18n.t('securities.requests.title')
  when 'safekeep new'
    I18n.t('securities.manage.safekeep_new')
  when 'standby letters of credit'
    I18n.t('products.standby_loc.title')
  when 'pledge new'
    I18n.t('securities.manage.pledge_new')
  when 'learn more'
    'Learn more'
  when 'letters of credit'
    I18n.t('letters_of_credit.title')
  when 'manage letters of credit'
    I18n.t('letters_of_credit.manage.title')
  when 'test features'
    I18n.t('admin.nav.secondary.features')
  when 'features'
    I18n.t('admin.features.title')
  when 'new letter of credit'
    I18n.t('letters_of_credit.request.title')
  when 'convertible'
    I18n.t('products.advances.convertible.title')
  when 'trade credit rules'
    I18n.t('admin.nav.secondary.trade_rules')
  when 'term rules'
    I18n.t('admin.term_rules.title')
  when 'add advance availability'
    I18n.t('admin.advance_availability.title')
  when 'end of day shutoff'
    I18n.t('admin.shutoff_times.title')
  else
    raise 'unknown dropdown'
  end
  /\A#{Regexp.quote(title)}\z/
end
