class LetterOfCredit
  include ActiveModel::Model

  # The DEFAULT_ISSUANCE_FEE and DEFAULT_MAINTENANCE_FEE may eventually come from a service, but we have been asked by
  # Scott and Michael to hardcode them in until an appropriate service is built to expose this information.
  DEFAULT_ISSUANCE_FEE = 100
  DEFAULT_MAINTENANCE_FEE = '10 bps'
  EXPIRATION_MAX_DATE_RESTRICTION = 15.years # TODO: Validate expiration date as part of MEM-2149
  ISSUE_MAX_DATE_RESTRICTION = 1.week # TODO: Validate issue date as part of MEM-2151

  READ_ONLY_ATTRS = [:issuance_fee, :maintenance_fee, :request]
  ACCESSIBLE_ATTRS = [:lc_number, :beneficiary_name, :beneficiary_address, :amount, :issue_date, :expiration_date]
  DATE_ATTRS = [:issue_date, :expiration_date]
  REQUIRED_ATTRS = [:beneficiary_name, :amount, :issue_date, :expiration_date]
  SERIALIZATION_EXCLUDE_ATTRS = [:request].freeze

  attr_accessor *ACCESSIBLE_ATTRS
  attr_reader *READ_ONLY_ATTRS

  validates *REQUIRED_ATTRS, presence: true
  validates :amount, numericality: { greater_than: 0, only_integer: true}
  validate :issue_date_must_come_before_expiration_date
  validate :issue_date_within_range
  validate :expiration_date_within_range

  def initialize(request=ActionDispatch::TestRequest.new)
    @request = request
    calendar_service = CalendarService.new(@request)
    today = Time.zone.today
    @issuance_fee = DEFAULT_ISSUANCE_FEE
    @maintenance_fee = DEFAULT_MAINTENANCE_FEE
    @issue_date = calendar_service.find_next_business_day(today, 1.day)
    @expiration_date = calendar_service.find_next_business_day(@issue_date + 1.year, 1.day)
  end

  def self.from_hash(hash)
    obj = new
    obj.attributes = hash
    obj
  end

  def attributes=(hash)
    process_attribute = Proc.new do |key, value|
      value = case key.to_sym
      when *SERIALIZATION_EXCLUDE_ATTRS
        raise ArgumentError, "illegal attribute: #{key}"
      when *READ_ONLY_ATTRS
        next
      when *DATE_ATTRS
        value ? Time.zone.parse(value) : value
      when *ACCESSIBLE_ATTRS
        value
      else
        raise ArgumentError, "unknown attribute: #{key}"
      end
      send("#{key}=", value)
    end
    indifferent_hash = hash.with_indifferent_access
    keys = indifferent_hash.keys.collect(&:to_sym)
    keys.each do |key|
      process_attribute.call(key, indifferent_hash[key])
    end
  end

  def amount=(amount)
    transformed_amount = if amount.respond_to?(:gsub)
      amount.gsub(',', '').to_i
    else
      amount.to_i if amount
    end
    @amount = transformed_amount
  end

  def beneficiary_name=(name)
    beneficiary_match = BeneficiariesService.new(request).all.select{|beneficiary| beneficiary[:name] == name }
    beneficiary_match.present? ? self.beneficiary_address = beneficiary_match.first[:address] : nil
    @beneficiary_name = name
  end

  private

  def issue_date_must_come_before_expiration_date
    if issue_date && expiration_date
      errors.add(:expiration_date, :before_issue_date) unless issue_date < expiration_date
    end
  end

  def issue_date_within_range
    errors.add(:issue_date, :invalid) unless !issue_date || date_within_range(issue_date, ISSUE_MAX_DATE_RESTRICTION)
  end

  def expiration_date_within_range
    errors.add(:expiration_date, :invalid) unless !expiration_date || date_within_range(expiration_date, EXPIRATION_MAX_DATE_RESTRICTION)
  end

  def date_within_range(date, max_date_restriction)
    today = Time.zone.today
    max_date = today + max_date_restriction
    holidays = CalendarService.new(request).holidays(today, max_date)
    !(date.try(:sunday?) || date.try(:saturday?)) && !(holidays.include?(date)) && date.try(:>=, today) && date.try(:<=, max_date)
  end
end