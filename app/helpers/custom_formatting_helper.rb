module CustomFormattingHelper
  def fhlb_formatted_currency(number)
    if number.to_i == 0
      '0'
    else
      number_to_currency(number, precision: 0)
    end
  end

  def fhlb_date_standard_numeric(date)
    date.to_date.strftime('%m-%d-%Y')
  end

  def fhlb_date_long_alpha(date)
    date.strftime('%B %-d, %Y')
  end

end