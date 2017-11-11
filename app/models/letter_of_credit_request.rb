class LetterOfCreditRequest
  include ActiveModel::Model
  include RedisBackedObject
  include CustomFormattingHelper

  # The DEFAULT_ISSUANCE_FEE, DEFAULT_MAINTENANCE_FEE, and DEFAULT_AMENDMENT_FEE may eventually come from a service, but we have been asked by
  # Scott and Michael to hardcode them in until an appropriate service is built to expose this information.
  DEFAULT_ISSUANCE_FEE = 100
  DEFAULT_AMENDMENT_FEE = 100
  DEFAULT_MAINTENANCE_FEE = '10 bps'
  EXPIRATION_MAX_DATE_RESTRICTION = 15.years
  ISSUE_MAX_DATE_RESTRICTION = 1.week
  ISSUE_DATE_TIME_RESTRICTION = '10:00:00'
  ISSUE_DATE_TIME_RESTRICTION_WINDOW = 5.minutes
  AMENDMENT_DATE_TIME_RESTRICTION = '10:00:00'
  AMENDMENT_DATE_TIME_RESTRICTION_WINDOW = 5.minutes
  REDIS_EXPIRATION_KEY_PATH =  'letter_of_credit_request.key_expiration'

  READ_ONLY_ATTRS = [:issuance_fee, :maintenance_fee, :amendment_fee, :request, :lc_number, :beneficiary, :current_par, :id, :owners,
                     :standard_borrowing_capacity, :max_term, :member_id, :remaining_financing_available, :evergreen_flag, :intraday_lc, :sort_code].freeze
  ACCESSIBLE_ATTRS = [:beneficiary_name, :beneficiary_address, :amount, :amended_amount, :attention,
                      :issue_date, :expiration_date, :amended_expiration_date, :amendment_date, :created_at, :created_by].freeze
  DATE_ATTRS = [:issue_date, :expiration_date, :amended_expiration_date, :amendment_date, :created_at].freeze
  REQUIRED_ATTRS = [:beneficiary_name, :amount, :issue_date, :expiration_date].freeze
  SERIALIZATION_EXCLUDE_ATTRS = [:request].freeze

  attr_accessor *ACCESSIBLE_ATTRS
  attr_reader *READ_ONLY_ATTRS

  validates *REQUIRED_ATTRS, presence: true
  validates :amount, numericality: { greater_than: 0, only_integer: true}
  validate :issue_date_must_come_before_expiration_date
  validate :issue_date_within_range, if: Proc.new{ |request| request.amendment_date.nil? }
  validate :issue_date_valid_for_today, if: Proc.new { |request| request.issue_date && request.issue_date.to_date == Time.zone.today }
  validate :expiration_date_within_range
  validate :amount_does_not_exceed_borrowing_capacity
  validate :amount_does_not_exceed_financing_availability
  validate :expiration_date_before_max_term
  validate :amended_expiration_on_or_after_original_expiration
  validate :amended_expiration_date_before_max_term
  validate :amended_amount_equal_or_greater_than_original_amount
  validate :amendment_date_not_prior_to_current_date

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

  def self.find_by_lc_number(member_id, lc_number, intraday_lc, request=nil)
    letter_of_credit_request = LetterOfCreditRequest.new(member_id, request)
    member_balances = MemberBalanceService.new(member_id, request)
    lc_details = member_balances.letter_of_credit(lc_number) || {}
    letter_of_credit_request.instance_variable_set(:@lc_number, lc_details[:lc_number])
    letter_of_credit_request.beneficiary_name = lc_details[:beneficiary]
    letter_of_credit_request.amount = lc_details[:current_par]
    letter_of_credit_request.amended_amount = lc_details[:current_par]
    letter_of_credit_request.issue_date = Time.zone.parse(lc_details[:trade_date]) if lc_details[:trade_date]
    letter_of_credit_request.expiration_date = Time.zone.parse(lc_details[:maturity_date]) if lc_details[:maturity_date]
    letter_of_credit_request.amended_expiration_date = Time.zone.parse(lc_details[:maturity_date]) if lc_details[:maturity_date]
    calendar_service = CalendarService.new(@request)
    today = Time.zone.today
    start_date = Time.zone.now > (Time.zone.parse(AMENDMENT_DATE_TIME_RESTRICTION) + AMENDMENT_DATE_TIME_RESTRICTION_WINDOW) ? today + 1.day : today
    letter_of_credit_request.amendment_date = calendar_service.find_next_business_day(start_date, 1.day)
    letter_of_credit_request.instance_variable_set(:@amendment_fee, DEFAULT_AMENDMENT_FEE)
    letter_of_credit_request.instance_variable_set(:@evergreen_flag, lc_details[:evergreen_flag])
    letter_of_credit_request.instance_variable_set(:@intraday_lc, intraday_lc.to_s == 'true')
    letter_of_credit_request.instance_variable_set(:@sort_code, lc_details[:sort_code])
    letter_of_credit_request
  end

  def evergreen?
    evergreen_flag.try(:upcase) == 'Y'
  end

  def public_deposit?
    !!sort_code.to_s.match(/L03|L12/i)
  end

  def amendable_online?
    !intraday_lc && !evergreen? && public_deposit? && beneficiary_name.present? && expiration_date.present? && issue_date.present? && date_within_range(expiration_date, issue_date + EXPIRATION_MAX_DATE_RESTRICTION) && expiration_date > Time.zone.today
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
      when :intraday_lc
        instance_variable_set('@intraday_lc', (value.to_s == 'true'))
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

  def amended_amount=(amended_amount)
    transformed_amount = if amended_amount.respond_to?(:gsub)
       amended_amount.gsub(',', '').to_i
     else
       amended_amount.to_i if amended_amount
     end
    @amended_amount = transformed_amount
  end

  def beneficiary_name=(name)
    beneficiary_match = BeneficiariesService.new(request).beneficiaries(member_id).select{|beneficiary| beneficiary[:name] == name }
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

  def amend_execute(requester_name)
    self.created_by = requester_name
    self.created_at = Time.zone.now
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
    amount_to_validate = amended_amount.nil? ? amount : amended_amount
    errors.add(:amount, :exceeds_borrowing_capacity) unless !amount_to_validate || amount_to_validate <= standard_borrowing_capacity
  end

  def amount_does_not_exceed_financing_availability
    fetch_member_profile
    amount_to_validate = amended_amount.nil? ? amount : amended_amount
    errors.add(:amount, :exceeds_financing_availability) unless !amount_to_validate || amount_to_validate <= remaining_financing_available
  end

  def amended_expiration_date_before_max_term
   if amended_expiration_date && issue_date
      fetch_member_profile
      errors.add(:amended_expiration_date, :after_max_term) if amended_expiration_date.to_date > issue_date.to_date + max_term.months
    end
  end

  def expiration_date_before_max_term
    if expiration_date && issue_date
      fetch_member_profile
      errors.add(:expiration_date, :after_max_term) if expiration_date.to_date > issue_date.to_date + max_term.months
    end
  end

  def amended_expiration_on_or_after_original_expiration
    if expiration_date && amended_expiration_date
      errors.add(:amended_expiration_date, :amended_exp_date_prior_to_original) if amended_expiration_date.to_date < expiration_date.to_date
    end
  end

  def amended_amount_equal_or_greater_than_original_amount
    if amount && amended_amount
      errors.add(:amended_amount, :amended_amount_less_than_original_amount) if amended_amount < amount
    end
  end

  def amendment_date_not_prior_to_current_date
    if amendment_date
      errors.add(:amendment_date, :amendment_date_prior_to_current_date) if amendment_date.to_date < Time.zone.today
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
