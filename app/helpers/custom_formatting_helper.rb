module CustomFormattingHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::NumberHelper

  def fhlb_formatted_currency(number, options={})
    options.reverse_update({html: true, negative_format: '%u(%n)', force_unit: false})
    return nil if number.nil? && options[:optional_number]
    return t('global.missing_value') if number.nil?
    formatted = if !options[:force_unit] && number == 0
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
    return t('global.missing_value') if number.nil?
    fhlb_formatted_currency(number, options.merge(precision: 0))
  end

  def fhlb_formatted_number(number, options={})
    options.reverse_update({html: true, precision: 0})
    return nil if number.nil? && options[:optional_number]
    return t('global.missing_value') if number.nil?
    formatted = number_with_precision(number.abs, options.merge(delimiter: ','))
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
    return t('global.missing_value') if date.nil?
    date.to_date.strftime('%m/%d/%Y')
  end

  def fhlb_date_long_alpha(date)
    return t('global.missing_value') if date.nil?
    date.to_date.strftime('%B %-d, %Y')
  end

  def fhlb_date_short_alpha(date)
    return t('global.missing_value') if date.nil?
    date.to_date.strftime('%B %Y')
  end

  def fhlb_date_quarter(date)
    return t('global.missing_value') if date.nil?
    date = date.to_date
    quarter = (date.month / 3.0).ceil
    I18n.t("dates.quarters.#{quarter}", year: date.year)
  end

  def fhlb_datetime_standard_numeric(datetime)
    return t('global.missing_value') if datetime.nil?
    datetime.to_datetime.strftime('%l:%M %P %m/%d/%Y')
  end

  def fhlb_report_date_numeric(date)
    return t('global.missing_value') if date.nil?
    date.to_date.strftime('%-m-%-d-%Y')
  end

  def fhlb_formatted_phone_number(number, ext=nil)
    return nil unless number
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
    return t('global.missing_value') if number.nil?
    number_to_percentage(number, precision: precision)
  end

  def fhlb_formated_currency_unit(number, unit='$', precision=0)
    unit_class = content_tag(:span, unit, class: 'alignleft')
    number_class = content_tag(:span, fhlb_formatted_number(number, precision: precision), class: 'alignright')
    inner_content = number.blank?? number_class : unit_class + number_class
    content_tag(:span, inner_content, class: 'currency-alignment')
  end

  def mask_email(email)
    if email
      parts = email.match(/\A(.)(.*)@(.)(.*)(\..*)\z/)
      if parts && parts.length > 5
        parts[1] + ("*" * parts[2].length) + '@' + parts[3] + ("*" * parts[4].length) + parts[5]
      end
    end
  end

  def fhlb_first_intial_last_name(first_name=nil, last_name=nil)
    first_initial = first_name[0] if first_name && first_name.length > 0
    return last_name unless first_initial
    "#{first_initial}. #{last_name}".rstrip
  end

  def fhlb_initials_from_full_name(full_name)
    return '' unless full_name
    tokens = full_name.strip.split(/\s+/m).compact
    return '' unless tokens.size > 0
    tokens.map {|t| t.first.upcase }.join
  end
end