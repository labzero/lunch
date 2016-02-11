Then(/^I should be on the membership "(.*?)" page$/) do |page_type|
  text = case page_type
           when "overview"
             I18n.t('resources.membership.overview.title')
           when "applications"
             I18n.t('resources.membership.applications.title')
           when 'credit union application'
             I18n.t('resources.membership.credit_union.title')
         end
  page.assert_selector('.resource h1', text: text, exact: true)
end

When(/^I click on the "(.*?)" link on the applications page$/) do |application_type|
  text = case application_type
           when 'credit union'
             I18n.t('resources.membership.applications.charter_types.credit_union')
         end
  page.click_link(text)
end