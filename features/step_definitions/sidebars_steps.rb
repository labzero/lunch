Then(/^I should see a Borrowing Capacity sidebar$/) do
  sidebar = page.find('.sidebar-borrowing-capacity')
  headers = [I18n.t('advances.add_advance.borrowing_capacity.total_borrowing_capacity'), I18n.t('advances.add_advance.borrowing_capacity.remaining_borrowing_capacity'), I18n.t('advances.add_advance.borrowing_capacity.remaining')]
  labels = [I18n.t('advances.add_advance.borrowing_capacity.standard'), I18n.t('advances.add_advance.borrowing_capacity.sbc_agency'), I18n.t('advances.add_advance.borrowing_capacity.sbc_aaa'), I18n.t('advances.add_advance.borrowing_capacity.sbc_aa'), I18n.t('advances.add_advance.borrowing_capacity.financing_avail'), I18n.t('advances.add_advance.borrowing_capacity.stock_leverage'), I18n.t('reports.pages.account_summary.financing_availability.maximum_term')]
  headers.each do |header|
    sidebar.assert_selector('h3', text: /#{header}/i)
  end
  labels.each do |label|
    sidebar.assert_selector('table .label', text: /#{label}/i)
  end
end