Then(/^I should see (\d) authorized users?$/) do |users|
  number_of_cells = users.to_i * 2 # avoids false matching when looking for 1 user and the table is displaying its empty state
  page.assert_selector('.authorizations-table tbody td', count: (number_of_cells))
end

Then(/^I should see user "(.*?)" with the "(.*?)" (footnoted )?authorization and no "(.*?)" authorization$/) do |name, included_role, footnoted, excluded_role|
  row = page.find('.authorizations-table td', text: name, exact: true).find(:xpath, '..')
  included_role = if footnoted
    I18n.t('global.footnoted_string', string: authorizations_roles(included_role))
  else
    authorizations_roles(included_role)
  end
  row.assert_selector('td li', text: /\A#{Regexp.quote(included_role)}\z/)
  row.assert_no_selector('td li', text: /\A#{Regexp.quote(excluded_role)}\z/)
end

def authorizations_roles(role)
  case role
    when 'Collateral'
      I18n.t('user_roles.collateral.title')
    when 'Resolution and Authorization'
      I18n.t('user_roles.resolution.title')
    when 'Securities Services'
      I18n.t('user_roles.securities.title')
  end
end