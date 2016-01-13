Then(/^I should be on the membership "(.*?)" page$/) do |page_type|
  text = case page_type
           when "overview"
             I18n.t('resources.membership.overview.title')
           when "applications"
             I18n.t('resources.membership.applications.title')
         end
  page.assert_selector('.resource h1', text: text, exact: true)
end