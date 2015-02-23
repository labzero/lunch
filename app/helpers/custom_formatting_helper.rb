module CustomFormattingHelper
  include ActionView::Helpers::TagHelper
  def fhlb_formatted_currency(number, options={})
    options.reverse_update({html: true, negative_format: '(%u%n)'})
    number = 0 if number.nil?
    formatted = if number == 0
      '0'
    else
      number_to_currency(number, options)
    end

    if options[:html]
      fhlb_formatted_number_html(number, formatted)
    else
      formatted
    end
  end

  def fhlb_formatted_currency_whole(number, options={})
    fhlb_formatted_currency(number, options.merge(precision: 0))
  end

  def fhlb_formatted_number(number, options={})
    options.reverse_update({html: true})
    number = 0 if number.nil?
    formatted = number_with_delimiter(number.abs, options)
    formatted = if number < 0
      "(#{formatted})"
    else
      formatted
    end

    if options[:html]
      fhlb_formatted_number_html(number, formatted)
    else
      formatted
    end
  end

  def fhlb_formatted_number_html(number, formatted_number)
    number_class = (number < 0 ? :'number-negative' : :'number-positive')
    content_tag(:span, formatted_number, class: number_class)
  end

  def fhlb_date_standard_numeric(date)
    date.to_date.strftime('%m/%d/%Y')
  end

  def fhlb_date_long_alpha(date)
    date.to_date.strftime('%B %-d, %Y')
  end

  def fhlb_date_quarter(date)
    date = date.to_date
    quarter = (date.month / 3.0).ceil
    I18n.t("dates.quarters.#{quarter}", year: date.year)
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

  def fhlb_add_unit_to_table_header(header, unit)
    header + ' (' + unit + ')'
  end

  def fhlb_formatted_percentage(number, precision=0)
    number_to_percentage(number, precision: precision)
  end
end