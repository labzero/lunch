module CustomFormattingHelper
  def fhlb_formatted_currency number
    if number.to_i == 0
      '0'
    else
      number_to_currency(number, precision: 0)
    end
  end

  def fhlb_formatted_date date
    date.to_date.strftime('%m-%d-%Y')
  end
end