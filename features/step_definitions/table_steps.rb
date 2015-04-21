Then(/^I should see the "(.*?)" column values in "(.*?)" order$/) do |column_name, sort_order|
  compare_sort_order(column_name, sort_order)
end

Then(/^I should see the "(.*?)" column values in "(.*?)" order on the "(.*)" table$/) do |column_name, sort_order, table_name|
  compare_sort_order(column_name, sort_order, get_selector_for_table_section(table_name))
end

Given(/^I should see the "(.*?)" column values in "(.*?)" order on the "(.*?)" parent table$/) do |column_name, sort_order, table_type|
  parent_selector = get_selector_for_table_section(table_type)
  table_selector = parent_selector + " .report-parent-table"
  compare_sort_order(column_name, sort_order, table_selector)
end

Then(/^I should see the "(.*?)" table and "(.*?)" subtables?$/) do |table_type, subtable_count|
  parent_selector = get_selector_for_table_section(table_type)
  page.assert_selector("#{parent_selector} .report-parent-table", count: 1)
  page.assert_selector("#{parent_selector} .report-sub-table", count: subtable_count)
end

When(/^I click the "(.*?)" column heading on the "(.*?)" parent table$/) do |heading, table_type|
  parent_selector = get_selector_for_table_section(table_type)
  page.find("#{parent_selector} th", text: heading).click
end

def get_selector_for_table_section(table_type)
  case table_type
    when "Standard Credit Program"
      selector = ".standard-credit-borrowing-capacity-tables"
    when "Securities-Backed Credit Program"
      selector = ".sbc-borrowing-capacity-tables"
    when 'Dividend Details'
      selector = '.table-dividend-details'
    else
      raise 'table title not recognized'
  end
  selector
end

def compare_sort_order(column_name, sort_order, table_selector='.report-table')
  column_index = page.evaluate_script("$('#{table_selector} thead th:contains(#{column_name})').index()") + 1 # will throw error if column name not present, which is good

  if !page.find("#{table_selector} tbody tr:first-child td:first-child")['class'].split(' ').include?('dataTables_empty')
    last_value = nil
    page.all("#{table_selector} tbody tr td:nth-child(#{column_index})").each do |element|
      case column_name
        when 'Date', 'Trade Date', 'Settlement Date', 'Issue Date', 'Start Date', 'End Date'
          value = Date.strptime(element.text, '%m/%d/%Y')
        when 'Certificate Sequence', 'Days Outstanding'
          value = element.text.to_i
        when 'Original Amount', 'Borrowing Capacity Remaining'
          value = element.text.delete('$,').to_i
        when 'Dividend'
          value = element.text.delete('$,').to_f
        when 'Average Shares Outstanding'
          value = element.text.delete(',').to_f
        when 'Shares Outstanding'
          value = element.text.delete(',').to_i
        else
          raise 'column_name not recognized'
      end

      if last_value
        if sort_order == 'ascending'
          expect(last_value <= value).to eq(true)
        elsif sort_order == 'descending'
          expect(last_value >= value).to eq(true)
        else
          raise "column_name not recognized"
        end

        if last_value
          if sort_order == 'ascending'
            expect(last_value <= value).to eq(true)
          elsif sort_order == 'descending'
            expect(last_value >= value).to eq(true)
          else
            raise 'sort_order not recognized'
          end
        end
        last_value = value
      end
    end
  end

end

def skip_if_table_empty(&block)
  if !page.first('.report-table tbody tr:first-child td:first-child')['class'].split(' ').include?('dataTables_empty')
    yield block
  end
end
