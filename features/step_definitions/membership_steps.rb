Then(/^I should be on the membership resource page$/) do
  page.assert_selector('.resource h1', text: I18n.t('resources.membership.overview.title'), exact: true)
end