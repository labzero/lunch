module FinancialInstrumentHelper
  def financial_instrument_standardize (product_type)
    case product_type
    when /WL\Z/
      product_type.gsub /WL\Z/, 'Wholeloan'
    else
      product_type
    end
  end

  def interest_rate_precision_by_advance_type(rate, type)
    arc_regexp = Regexp.new(/(?:[^a-z]|^)arc(?:[^a-z]|$)/i)
    decimal_places = determine_precision_to_n(rate, 7)
    if arc_regexp.match(type) || decimal_places > 5
      5
    elsif decimal_places > 2
      decimal_places
    else
      2
    end
  end

  def determine_precision_to_n(number, n)
    number = number.to_f
    precision = 0
    n.times do |i|
      i = n - i
      unless (((number*10**i).to_i) % 10**i) % 10 == 0
        precision = i
        break
      end
    end
    precision > n ? n : precision
  end
end