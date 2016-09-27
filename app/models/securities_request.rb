class SecuritiesRequest
  include ActiveModel::Model

  TRANSACTION_CODES = {
    standard: 'standard',
    repo: 'repo'
  }.freeze

  SETTLEMENT_TYPES = {
    free: 'free',
    vs_payment: 'vs_payment'
  }.freeze

  DELIVERY_TYPES = {
    dtc: 'dtc',
    fed: 'fed',
    mutual_fund: 'mutual_fund',
    physical_securities: 'physical_securities',
    transfer: 'transfer'
  }.freeze

  PLEDGE_TO_VALUES = {
    sbc: 'sbc',
    standard: 'standard'
  }.freeze

  KINDS = [:pledge_release, :safekept_release, :pledge_intake, :safekept_intake, :pledge_transfer, :safekept_transfer].freeze
  TRANSFER_KINDS = [:pledge_transfer, :safekept_transfer].freeze
  INTAKE_KINDS = [:pledge_intake, :safekept_intake].freeze
  SECURITIES_KINDS = [:safekept_release, :safekept_intake].freeze
  COLLATERAL_KINDS = [:pledge_release, :pledge_intake, :pledge_transfer, :safekept_transfer].freeze
  FORM_TYPES = [:pledge_release, :safekept_release, :pledge_intake, :safekept_intake]

  BROKER_INSTRUCTION_KEYS = [:transaction_code, :settlement_type, :trade_date, :settlement_date].freeze

  DELIVERY_INSTRUCTION_KEYS = {
    fed: [:clearing_agent_fed_wire_address_1, :clearing_agent_fed_wire_address_2, :aba_number, :fed_credit_account_number],
    dtc: [:clearing_agent_participant_number, :dtc_credit_account_number],
    mutual_fund: [:mutual_fund_company, :mutual_fund_account_number],
    physical_securities: [:delivery_bank_agent, :receiving_bank_agent_name, :receiving_bank_agent_address, :physical_securities_credit_account_number],
    transfer: []
  }.freeze

  ACCOUNT_NUMBER_TYPE_MAPPING = {
    fed: :fed_credit_account_number,
    dtc: :dtc_credit_account_number,
    mutual_fund: :mutual_fund_account_number,
    physical_securities: :physical_securities_credit_account_number
  }.freeze

  OTHER_PARAMETERS = [:request_id,
                      :delivery_type,
                      :member_id,
                      :pledged_account,
                      :safekept_account,
                      :pledge_to,
                      :form_type,
                      :authorized_by,
                      :authorized_date,
                      :kind].freeze

  ACCESSIBLE_ATTRS = (BROKER_INSTRUCTION_KEYS + OTHER_PARAMETERS + DELIVERY_INSTRUCTION_KEYS.values.flatten).freeze

  MAX_DATE_RESTRICTION = 3.months

  FED_AMOUNT_LIMIT = 50000000

  attr_accessor *ACCESSIBLE_ATTRS
  attr_reader :securities

  validates *[:delivery_type, :securities, :kind, :form_type], presence: true
  validates *[:pledged_account, :safekept_account], presence: true, if: Proc.new { |request| request.kind && TRANSFER_KINDS.include?(request.kind)  }
  validates :pledge_to, presence: true, if: Proc.new { |request| request.kind && request.kind == :pledge_intake || request.kind == :pledge_transfer  }
  validates *(DELIVERY_INSTRUCTION_KEYS[:fed] - [:fed_credit_account_number]), presence: true, if: Proc.new { |request| request.delivery_type && request.delivery_type == :fed }
  validates *(DELIVERY_INSTRUCTION_KEYS[:dtc] - [:dtc_credit_account_number]), presence: true, if: Proc.new { |request| request.delivery_type && request.delivery_type == :dtc }
  validates *DELIVERY_INSTRUCTION_KEYS[:mutual_fund], presence: true, if: Proc.new { |request| request.delivery_type && request.delivery_type == :mutual_fund }
  validates *(DELIVERY_INSTRUCTION_KEYS[:physical_securities] - [:physical_securities_credit_account_number]), presence: true, if: Proc.new { |request| request.delivery_type && request.delivery_type == :physical_securities }
  validate :original_par_under_fed_limit, if: Proc.new { |request| request.delivery_type && request.delivery_type == :fed }

  with_options if: Proc.new { |request| !TRANSFER_KINDS.include?(request.kind) } do
    validates *BROKER_INSTRUCTION_KEYS, presence: true
    validate :trade_date_must_come_before_settlement_date
    validate :trade_date_within_range
    validate :settlement_date_within_range
    validate :valid_securities_payment_amount?
  end

  def kind=(kind)
    kind = kind.try(:to_sym)
    raise ArgumentError, "`kind` must be one of: #{KINDS}" unless KINDS.include?(kind)
    case kind
    when :pledge_transfer
      @form_type = :pledge_intake
      @delivery_type = :transfer
    when :safekept_transfer
      @form_type = :pledge_release
      @delivery_type = :transfer
    else
      @form_type = kind
    end
    @kind = kind
  end

  def form_type=(form_type)
    form_type = form_type.try(:to_sym)
    raise ArgumentError, "`form_type` must be one of: #{FORM_TYPES}" unless FORM_TYPES.include?(form_type)
    if delivery_type == :transfer
      case form_type
      when :pledge_intake
        @kind = :pledge_transfer
      when :pledge_release
        @kind = :safekept_transfer
      else
        raise ArgumentError, '`form_type` must be :pledge_intake or :pledge_release when `delivery_type` is :transfer'
      end
    else
      @kind = form_type
    end
    @form_type = form_type
  end

  def delivery_type=(delivery_type)
    delivery_type = delivery_type.try(:to_sym)
    raise ArgumentError, "`delivery_type` must be one of: #{DELIVERY_TYPES.keys}" unless DELIVERY_TYPES.keys.include?(delivery_type)
    if delivery_type == :transfer && form_type
      case form_type
      when :pledge_intake
        @kind = :pledge_transfer
      when :pledge_release
        @kind = :safekept_transfer
      else
        raise ArgumentError, '`form_type` must be :pledge_intake or :pledge_release when `delivery_type` is :transfer'
      end
    end
    @delivery_type = delivery_type
  end

  def settlement_type=(settlement_type)
    settlement_type = settlement_type.try(:to_sym)
    raise ArgumentError, "`settlement_type` must be one of: #{SETTLEMENT_TYPES.keys}" unless SETTLEMENT_TYPES.keys.include?(settlement_type)
    @settlement_type = settlement_type
  end

  def self.from_hash(hash)
    obj = new
    obj.attributes = hash
    obj
  end

  def attributes=(hash)
    hash.each do |key, value|
      key = key.to_sym
      value = case key
      when :trade_date, :settlement_date, :authorized_date
        value ? Time.zone.parse(value) : value
      when :transaction_code, :pledge_to
        value.try(:to_sym)
      when :securities, *ACCESSIBLE_ATTRS
        value
      else
        raise ArgumentError, "unknown attribute: '#{key}'"
      end
      send("#{key.to_sym}=", value)
    end
  end

  def securities=(securities)
    securities = if securities.is_a?(String)
      JSON.parse(securities)
    else
      securities || []
    end
    securities.collect! do |security|
      if security.is_a?(Security)
        security
      elsif security.is_a?(String)
        Security.from_json(security)
      elsif security.is_a?(Hash)
        Security.from_hash(security)
      else
        raise ArgumentError, "unable to process security with class: '#{security.class}'"
      end
    end
    @securities = securities
  end

  def broker_instructions
    {
      transaction_code: transaction_code,
      settlement_type: settlement_type,
      trade_date: trade_date,
      settlement_date: settlement_date,
      safekept_account: safekept_account,
      pledged_account: pledged_account,
      pledge_to: pledge_to
    }
  end

  def delivery_instructions
    delivery_instructions_hash = {
      delivery_type: delivery_type
    }
    DELIVERY_INSTRUCTION_KEYS[delivery_type.to_sym].each do |attr|
      if ACCOUNT_NUMBER_TYPE_MAPPING.values.include?(attr)
        delivery_instructions_hash[:account_number] = self.send(attr)
      else
        delivery_instructions_hash[attr] = self.send(attr)
      end
    end
    delivery_instructions_hash
  end

  def request_id=(new_value)
    if new_value.is_a?(String) || new_value.is_a?(Numeric) || new_value.nil? || new_value.is_a?(FalseClass)
      @request_id = new_value.present? ? new_value : nil
    else
      raise ArgumentError, '`request_id` must be a string, number or blank'
    end
  end

  def is_collateral?
    self.kind.in?(COLLATERAL_KINDS)
  end

  private

  def trade_date_must_come_before_settlement_date
    if trade_date && settlement_date
      errors.add(:settlement_date, :before_trade_date) unless trade_date <= settlement_date
    end
  end

  def trade_date_within_range
    errors.add(:trade_date, :invalid) unless !trade_date || date_within_range(trade_date, :trade_date)
  end

  def settlement_date_within_range
    errors.add(:settlement_date, :invalid) unless !settlement_date ||  date_within_range(settlement_date, :settlement_date)
  end

  def date_within_range(date, field)
    today = Time.zone.today
    max_date = today + MAX_DATE_RESTRICTION
    holidays = CalendarService.new(ActionDispatch::TestRequest.new).holidays(today, max_date)
    valid = !(date.try(:sunday?) || date.try(:saturday?)) && !(holidays.include?(date)) && date.try(:<=, max_date)
    if field == :trade_date
      valid
    else
      valid && date.try(:>=, today)
    end
  end

  def valid_securities_payment_amount?
    unless securities.blank? || settlement_type.blank? || TRANSFER_KINDS.include?(kind)
      payment_amount_present = securities.map { |security| security.payment_amount.present? }

      if payment_amount_present.uniq.length == 1 && payment_amount_present.first
        # All securities have a payment_amount
        errors.add(:securities, :payment_amount_present) if settlement_type == :free
      elsif payment_amount_present.uniq.length == 1
        # No securities have a payment_amount
        errors.add(:securities, :payment_amount_missing) if settlement_type == :vs_payment
      else
        # Some securities have a payment_amount and some don't
        errors.add(:securities, :payment_amount_present) if settlement_type == :free
        errors.add(:securities, :payment_amount_missing) if settlement_type == :vs_payment
      end
    end
  end

  def original_par_under_fed_limit
    unless securities.blank?
      over_fed_limit = false
      securities.each do |security|
        if security.original_par > FED_AMOUNT_LIMIT
          over_fed_limit = true
          break
        end
      end
      errors.add(:securities, :original_par) if over_fed_limit
    end
  end
end
