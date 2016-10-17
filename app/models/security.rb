class Security
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON

  RELEASE_REQUEST_PARAMETERS = [:detail_id, :cusip, :description, :original_par, :payment_amount].freeze
  OTHER_PARAMETERS = [:custodian_name, :custody_account_number, :custody_account_type, :security_pledge_type, :pool_number, :reg_id, :coupon_rate, :factor, :current_par, :price, :market_value, :maturity_date, :factor_date, :price_date, :eligibility, :authorized_by, :borrowing_capacity].freeze
  ACCESSIBLE_ATTRS = RELEASE_REQUEST_PARAMETERS + OTHER_PARAMETERS
  REQUIRED_ATTRS = [:cusip, :original_par]
  CURRENCY_ATTRIBUTES = [:original_par, :payment_amount]

  attr_accessor *ACCESSIBLE_ATTRS

  validates :cusip, presence: true
  validates :original_par, numericality: {greater_than: 0}, allow_blank: false
  validates *CURRENCY_ATTRIBUTES, numericality: true, allow_blank: true
  validate :cusip_format

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
      when *CURRENCY_ATTRIBUTES
        (value.is_a?(Numeric) || value.nil?) ? value.to_f : value
      when *ACCESSIBLE_ATTRS
        value
      else
        raise ArgumentError, "unknown attribute: '#{key}'"
      end
      send("#{key}=", value)
    end
  end

  def attributes
    attrs = {}
    ACCESSIBLE_ATTRS.each do |key|
      attrs[key] = nil if send(key)
    end
    attrs
  end

  def cusip=(cusip)
    @cusip = cusip.try(:upcase)
  end

  private

  def cusip_format
    if cusip
      cusip_valid = begin
        !!SecurityIdentifiers::CUSIP.new(cusip).valid?
      rescue SecurityIdentifiers::InvalidFormat
        false
      end
      errors.add(:cusip, :invalid) unless cusip_valid
    end
  end

end