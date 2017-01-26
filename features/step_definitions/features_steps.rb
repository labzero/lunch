Then(/^I see a list of features and their state$/) do
  table_class = '.admin-features-table'
  state_classes = ['.admin-conditional-icon', '.admin-on-icon', '.admin-off-icon']
  page.assert_selector("#{table_class} tbody tr", minimum: 1)
  state_selector = state_classes.collect {|k| k.prepend(table_class + ' ') }
  page.assert_selector(state_selector.join(', '), minimum: 1)
end
