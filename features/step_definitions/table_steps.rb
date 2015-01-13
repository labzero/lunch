Then(/^I should see the "(.*?)" column values in "(.*?)" order$/) do |column_name, sort_order|
  column_index = page.evaluate_script("$('thead th:contains(#{column_name})').index()") + 1 # will throw error if column name not present, which is good

  last_value = nil
  if !page.find('.report-table tbody td:first-child')['class'].split(' ').include?('dataTables_empty')
    page.all("tbody tr td:nth-child(#{column_index})").each do |element|
      case column_name
      when "Date"
        value = Date.strptime(element.text, '%m/%d/%Y')
      when "Certificate Sequence"
        value = element.text.to_i
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
