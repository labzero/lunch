class Security
  include ActiveModel::Model

  RELEASE_REQUEST_PARAMETERS = [:cusip, :description, :original_par, :payment_amount].freeze
  OTHER_PARAMETERS = [:custody_account_number, :custody_account_type, :security_pledge_type, :pool_number, :reg_id, :coupon_rate, :factor, :current_par, :price, :market_value, :maturity_date, :factor_date, :price_date, :eligibility, :authorized_by, :borrowing_capacity].freeze
  ACCESSIBLE_ATTRS = RELEASE_REQUEST_PARAMETERS + OTHER_PARAMETERS

  attr_accessor *ACCESSIBLE_ATTRS

  def self.from_json(json)
    from_hash(JSON.parse(json).with_indifferent_access)
  end

  def self.from_hash(hash)
    obj = new
    obj.attributes = hash
    obj
  end

  def self.human_custody_account_type_to_status(custody_account_type)
    custody_account_type = custody_account_type.to_s.upcase if custody_account_type
    case custody_account_type
      when 'P'
        I18n.t('securities.manage.pledged')
      when 'U'
        I18n.t('securities.manage.safekept')
      else
        I18n.t('global.missing_value')
    end
  end

  def attributes=(hash)
    hash.each do |key, value|
      key = key.to_sym
      value = case key
        when *ACCESSIBLE_ATTRS
          value
        else
          raise ArgumentError, "unknown attribute: '#{key}'"
      end
      send("#{key}=", value)
    end
  end

  def cusip=(cusip)
    @cusip = cusip.try(:upcase)
  end

end