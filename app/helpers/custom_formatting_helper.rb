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

  def fhlb_formatted_phone_number(number, ext=nil)
    number.gsub!(/[^0-9]/, '')
    ext.gsub!(/[^0-9]/, '') if ext
    raise ArgumentError.new('number too short') if number.length < 10
    raise ArgumentError.new('number too long') if number.length > 11
    if number.length == 11
      if number[0] == '1'
        number = number[1..-1]
      else
        raise ArgumentError.new('11 digit numbers need to start with a 1')
      end
    end
    formated_number = "(#{number[0..2]}) #{number[3..5]}-#{number[6..-1]}"
    if ext.present?
      formated_number += ", ext. #{ext}"
    end
    formated_number
  end
end