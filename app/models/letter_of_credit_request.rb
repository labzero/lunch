class LetterOfCreditRequest
  include ActiveModel::Model
  include RedisBackedObject
  include CustomFormattingHelper

  # The DEFAULT_ISSUANCE_FEE and DEFAULT_MAINTENANCE_FEE may eventually come from a service, but we have been asked by
  # Scott and Michael to hardcode them in until an appropriate service is built to expose this information.
  DEFAULT_ISSUANCE_FEE = 100
  DEFAULT_MAINTENANCE_FEE = '10 bps'
  EXPIRATION_MAX_DATE_RESTRICTION = 15.years
  ISSUE_MAX_DATE_RESTRICTION = 1.week
  ISSUE_DATE_TIME_RESTRICTION = '11:00:00'
  ISSUE_DATE_TIME_RESTRICTION_WINDOW = 5.minutes
  REDIS_EXPIRATION_KEY_PATH =  'letter_of_credit_request.key_expiration'

  READ_ONLY_ATTRS = [:issuance_fee, :maintenance_fee, :request, :lc_number, :id, :owners, :member_id,
                     :standard_borrowing_capacity, :max_term, :remaining_financing_available].freeze
  ACCESSIBLE_ATTRS = [:beneficiary_name, :beneficiary_address, :amount, :attention, :issue_date, :expiration_date, :created_at, :created_by].freeze
  DATE_ATTRS = [:issue_date, :expiration_date, :created_at].freeze
  REQUIRED_ATTRS = [:beneficiary_name, :amount, :issue_date, :expiration_date].freeze
  SERIALIZATION_EXCLUDE_ATTRS = [:request].freeze

  attr_accessor *ACCESSIBLE_ATTRS
  attr_reader *READ_ONLY_ATTRS

  validates *REQUIRED_ATTRS, presence: true
  validates :amount, numericality: { greater_than: 0, only_integer: true}
  validate :issue_date_must_come_before_expiration_date
  validate :issue_date_within_range
  validate :issue_date_valid_for_today, if: Proc.new { |request| request.issue_date && request.issue_date.to_date == Time.zone.today }
  validate :expiration_date_within_range
  validate :amount_does_not_exceed_borrowing_capacity
  validate :amount_does_not_exceed_financing_availability
  validate :expiration_date_before_max_term

  def initialize(member_id, request=ActionDispatch::TestRequest.new)
    @member_id = member_id
    @request = request
    calendar_service = CalendarService.new(@request)
    today = Time.zone.today
    @issuance_fee = DEFAULT_ISSUANCE_FEE
    @maintenance_fee = DEFAULT_MAINTENANCE_FEE
    start_date = Time.zone.now > Time.zone.parse(ISSUE_DATE_TIME_RESTRICTION) ? today + 1.day : today
    @issue_date = calendar_service.find_next_business_day(start_date, 1.day)
    @expiration_date = calendar_service.find_next_business_day(@issue_date + 1.year, 1.day)
  end

  def id
    @id ||= SecureRandom.uuid
  end

  def attributes
    attrs = {}
    (READ_ONLY_ATTRS + ACCESSIBLE_ATTRS - SERIALIZATION_EXCLUDE_ATTRS).each do |key|
      attrs[key] = nil if send(key)
    end
    attrs
  end

  def attributes=(hash)
    process_attribute = Proc.new do |key, value|
      case key.to_sym
      when *SERIALIZATION_EXCLUDE_ATTRS
        raise ArgumentError, "illegal attribute: #{key}"
      when :owners
        @owners = value.to_set
      when *READ_ONLY_ATTRS
        instance_variable_set("@#{key}", value)
      when *DATE_ATTRS
        value = Time.zone.parse(value) if value
        send("#{key}=", value)
      when *ACCESSIBLE_ATTRS
        send("#{key}=", value)
      else
        raise ArgumentError, "unknown attribute: #{key}"
      end
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

  def execute(requester_name)
    self.created_by = requester_name
    self.created_at = Time.zone.now
    begin
      set_lc_number
      true
    rescue Exception
      false
    end
  end

  def owners
    @owners ||= Set.new
  end

  def standard_borrowing_capacity
    @standard_borrowing_capacity ||= (@member_profile[:collateral_borrowing_capacity][:standard][:remaining].to_i if @member_profile)
  end

  def max_term
    @max_term ||= (@member_profile[:maximum_term].to_i if @member_profile)
  end

  def remaining_financing_available
    @remaining_financing_available ||= (@member_profile[:remaining_financing_available].to_i if @member_profile)
  end

  def self.from_json(json, request)
    new(nil, request).from_json(json)
  end

  def self.policy_class
    LettersOfCreditPolicy
  end

  private

  def issue_date_must_come_before_expiration_date
    if issue_date && expiration_date
      errors.add(:expiration_date, :before_issue_date) unless issue_date < expiration_date
    end
  end

  def issue_date_within_range
    today = Time.zone.today
    min_start_date = past_issue_date_restriction_window? ? today + 1.day : today
    max_date = min_start_date + ISSUE_MAX_DATE_RESTRICTION
    errors.add(:issue_date, :invalid) unless !issue_date || date_within_range(issue_date, max_date)
  end

  def expiration_date_within_range
    max_date = (issue_date || Time.zone.today) + EXPIRATION_MAX_DATE_RESTRICTION
    errors.add(:expiration_date, :invalid) unless !expiration_date || date_within_range(expiration_date, max_date)
  end

  def date_within_range(date, max_date)
    today = Time.zone.today
    holidays = CalendarService.new(request).holidays(today, max_date)
    !(date.try(:sunday?) || date.try(:saturday?)) && !(holidays.include?(date)) && date.try(:>=, today) && date.try(:<=, max_date)
  end

  def sequence_name
    "LC_#{Time.zone.today.year}"
  end

  def next_in_sequence
    name = ActiveRecord::Base.connection.quote_table_name(sequence_name)
    ActiveRecord::Base.connection.execute("SELECT #{name}.nextval FROM dual").fetch.first.to_i
  end

  def create_sequence
    name = ActiveRecord::Base.connection.quote_table_name(sequence_name)
    statement = <<-SQL
      CREATE SEQUENCE #{name} 
      START WITH 500
      INCREMENT BY 1
      NOCACHE
    SQL
    ActiveRecord::Base.connection.execute(statement)
  end

  def set_lc_number
    @lc_number ||= (
    counter = begin
      next_in_sequence
    rescue ActiveRecord::StatementInvalid => e
      next_in_new_sequence
    end
    "#{Time.zone.today.year}-#{counter}"
    )
  end

  def next_in_new_sequence
    create_sequence rescue ActiveRecord::StatementInvalid
    next_in_sequence
  end

  def amount_does_not_exceed_borrowing_capacity
    fetch_member_profile
    errors.add(:amount, :exceeds_borrowing_capacity) unless !amount || amount <= standard_borrowing_capacity
  end

  def amount_does_not_exceed_financing_availability
    fetch_member_profile
    errors.add(:amount, :exceeds_financing_availability) unless !amount || amount <= remaining_financing_available
  end

  def expiration_date_before_max_term
    if expiration_date && issue_date
      fetch_member_profile
      errors.add(:expiration_date, :after_max_term) if expiration_date > issue_date.to_date + max_term.months
    end
  end

  def fetch_member_profile
    @member_profile ||= MemberBalanceService.new(member_id, request).profile
  end

  def issue_date_valid_for_today
    errors.add(:issue_date, :no_longer_valid) if past_issue_date_restriction_window?
  end

  def past_issue_date_restriction_window?
    Time.zone.now > (Time.zone.parse(ISSUE_DATE_TIME_RESTRICTION) + ISSUE_DATE_TIME_RESTRICTION_WINDOW)
  end
end
