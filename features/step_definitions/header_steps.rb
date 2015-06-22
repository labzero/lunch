Given(/^I don't see the (reports|resources) dropdown$/) do |dropdown|
  page.find('.logo').hover # make sure the mouse isn't left on top of the nav bar from a different test
  report_menu = page.find('.nav-menu', text: dropdown_title_regex(dropdown))
  report_menu.parent.assert_selector('.nav-dropdown', visible: :hidden)
end

When(/^I hover on the (reports|resources) link in the header$/) do |dropdown|
  page.find('.nav-menu', text: dropdown_title_regex(dropdown)).hover
end

Then(/^I should see the (reports|resources) dropdown$/) do |dropdown|
  report_menu = page.find('.nav-menu', text: dropdown_title_regex(dropdown))
  report_menu.parent.assert_selector('.nav-dropdown', visible: true)
end

When(/^I click on the (reports|guides) link in the header$/) do |link|
  page.find('.page-header .secondary-nav a', text: dropdown_title_regex(link)).click
end

def dropdown_title_regex(dropdown)
  title = case dropdown
  when 'reports'
    I18n.t('reports.title')
  when 'resources'
    I18n.t('nav.secondary.resources')
  when 'guides'
    I18n.t('resources.guides.title')
  else
    raise 'unknown dropdown'
  end
  /\A#{Regexp.quote(title)}\z/
end