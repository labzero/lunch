module FinancialInstrumentHelper
  def financial_instrument_standardize (product_type)
    case product_type
    when /WL\Z/
      product_type.gsub /WL\Z/, 'Wholeloan'
    else
      product_type
    end
  end
end