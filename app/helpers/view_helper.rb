module ViewHelper
  def fhlb_formatted_currency number
    if number.to_i == 0
      '0'
    else
      number_to_currency(number, precision: 0)
    end
  end
end