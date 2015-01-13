Then(/^I should see the "(.*?)" column values in "(.*?)" order$/) do |column_name, sort_order|
  column_index = page.evaluate_script("$('thead th:contains(#{column_name})').index()") + 1 # will throw error if column name not present, which is good
  first_row_text = page.find("tbody tr:first-child td:nth-child(#{column_index})").text
  last_row_text = page.find("tbody tr:last-child td:nth-child(#{column_index})").text

  case column_name
  when "Date"
    top_val = Date.strptime(first_row_text, '%m/%d/%Y')
    bottom_val = Date.strptime(last_row_text, '%m/%d/%Y')
  when "Certificate Sequence"
    top_val = first_row_text.to_i
    bottom_val = last_row_text.to_i
  else
    raise "column_name not recognized"
  end
  
  if sort_order == 'ascending'
    expect(top_val <= bottom_val).to eq(true)
  elsif sort_order == 'descending'
    expect(top_val >= bottom_val).to eq(true)
  else
    raise 'sort_order not recognized'
  end
end
