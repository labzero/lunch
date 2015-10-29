class AdvanceRequest

  class Error
    attr_reader :type, :code, :value

    def initialize(type, code, value=nil)
      @type = type
      @code = code
      @value = value
    end
  end

  include ActiveModel::Model
  include ActiveModel::Serializers::JSON
  include AASM

  STOCK_CHOICES = [:continue, :purchase].freeze
  ADVANCE_TYPES = [:whole, :agency, :aaa, :aa].freeze
  ADVANCE_TERMS = [
    :overnight, :open, :'1week', :'2week', :'3week', :'1month',
    :'2month', :'3month', :'6month', :'1year', :'2year', :'3year'
  ].freeze

  READONLY_ATTRS = [:signer, :timestamp, :checked_stock, :member_id, :old_rate].freeze
  REQUEST_PARAMETERS = [
    :exception_message, :cumulative_stock_required,
    :current_trade_stock_required, :pre_trade_stock_required, :net_stock_required, :gross_amount,
    :gross_cumulative_stock_required, :gross_current_trade_stock_required,
    :gross_pre_trade_stock_required, :gross_net_stock_required,
    :interest_day_count, :payment_on, :funding_date, :maturity_date, :initiated_at,
    :confirmation_number, :authorized_amount, :credit_max_amount, :collateral_max_amount,
    :collateral_authorized_amount, :trade_date
  ].freeze
  CORE_PARAMETERS = [:type, :rates, :term, :amount, :rate, :stock_choice].freeze
  PREVIEW_EXCLUDE_KEYS = [:advance_amount, :advance_rate, :advance_type, :advance_term, :status].freeze

  VALID_AMOUNT = /\A[0-9,]+(\.0?0?)?\z/i.freeze

  attr_accessor *CORE_PARAMETERS
  attr_accessor *REQUEST_PARAMETERS
  attr_reader *READONLY_ATTRS

  aasm do
    state :preview, initial: true
    state :executed

    event :execute, guards: [:terms_present?, :no_errors_present?] do
      before do
        perform_execute if may_execute? && terms_present? && no_errors_present? && validate_advance
      end
      transitions from: :preview, to: :executed
    end
  end

  def initialize(member_id, signer, request=nil)
    @member_id = member_id
    @signer = signer
    @request = request
  end

  def timestamp!
    @timestamp = Time.zone.now
  end

  def expired?(timeout=nil)
    unless timeout
      settings = etransact_service.settings
      raise 'No RateTimeout setting found' unless settings && settings[:rate_timeout]
      timeout = settings[:rate_timeout]
    end
    timestamp.present? && (Time.zone.now - timestamp >= timeout)
  end

  def rate_for(term, type)
    rates[type.to_sym][term.to_sym][:rate].to_f
  end

  def rate_for!(term, type)
    self.rate = rate_for(term, type)
  end

  def rate!
    rate_for!(term, type) unless rate
    rate
  end

  def rate=(new_rate)
    @rate = new_rate.to_f
  end

  def rates
    unless @rates
      @rates = rate_service.quick_advance_rates(member_id)
      notify_if_rate_bands_exceeded(@rates)
    end
    @rates 
  end

  def term=(term)
    term = term.try(:to_sym)
    raise "Unknown Advance Term: #{term}" unless ADVANCE_TERMS.include?(term)
    old_term = @term
    @term = term
    if old_term != term && type
      rate_for!(self.term, type)
    end
  end

  def type=(type)
    type = type.try(:to_sym)
    raise "Unknown Advance Type: #{type}" unless ADVANCE_TYPES.include?(type)
    old_type = @type
    @type = type
    if old_type != type && term
      rate_for!(term, self.type)
    end
  end

  def amount=(amount)
    @amount = transform_amount(amount, :amount)
  end

  def gross_amount=(amount)
    @gross_amount = transform_amount(amount, :gross_amount)
  end

  def stock_choice=(choice)
    choice = choice.to_sym
    raise "Unknown Stock Choice: #{choice}" if choice && !STOCK_CHOICES.include?(choice)
    @stock_choice = choice
  end

  def total_amount
    purchase_stock? ? gross_amount : amount
  end

  def sta_debit_amount
    stock_cost = (purchase_stock? ? gross_cumulative_stock_required : cumulative_stock_required)
    stock_cost.to_f if stock_cost
  end

  def validate_advance
    clear_errors
    perform_limit_check
    perform_preview
    perform_rate_check
    no_errors_present?
  end

  def rate_changed?
    old_rate.present? && old_rate != rate
  end

  def errors
    @errors ||= []
  end

  def program_name
    case type
    when :whole
      I18n.t('dashboard.quick_advance.table.axes_labels.standard')
    when :aa, :aaa, :agency
      I18n.t('dashboard.quick_advance.table.axes_labels.securities_backed')
    else
      type
    end
  end

  def term_description
    case term
    when :overnight, :open
      I18n.t('dashboard.quick_advance.vrc_title')
    when nil
      nil
    else
      I18n.t('dashboard.quick_advance.frc_title')
    end
  end

  def human_interest_day_count
    case interest_day_count
    when nil       then nil
    when 'ACT/ACT' then I18n.t('dashboard.quick_advance.table.ACTACT')
    when 'ACT/360' then I18n.t('dashboard.quick_advance.table.ACT360')
    else raise ArgumentError.new('interest day count code should be either ACT/ACT or ACT/360')
    end
  end

  def human_type
    case type
    when :whole
      I18n.t('dashboard.quick_advance.table.whole_loan')
    when :agency
      I18n.t('dashboard.quick_advance.table.agency')
    when :aaa
      I18n.t('dashboard.quick_advance.table.aaa')
    when :aa
      I18n.t('dashboard.quick_advance.table.aa')
    else
      type
    end
  end

  def human_term
    case term
    when *ADVANCE_TERMS
      I18n.t("dashboard.quick_advance.table.axes_labels.#{term}")
    else
      term
    end
  end

  def collateral_type
    case type
    when :whole
      I18n.t('dashboard.quick_advance.table.mortgage')
    when :agency
      I18n.t('dashboard.quick_advance.table.agency')
    when :aaa
      I18n.t('dashboard.quick_advance.table.aaa')
    when :aa
      I18n.t('dashboard.quick_advance.table.aa')
    else
      type
    end
  end

  def current_state
    aasm.current_state
  end

  def attributes=(hash)
    hash.each do |key, value|
      case key.to_sym
      when :current_state
        aasm.current_state = value
      when *READONLY_ATTRS
        instance_variable_set("@#{key}", value)
      when *(REQUEST_PARAMETERS + CORE_PARAMETERS)
        send("#{key}=", value)
      else
        raise "unknown attribute: #{key}"
      end
    end
  end

  def attributes
    attrs = {}
    (READONLY_ATTRS + REQUEST_PARAMETERS + CORE_PARAMETERS).each do |key|
      attrs[key] = nil if send(key)
    end
    attrs[:current_state] = current_state
    attrs
  end

  def self.from_json(json, request=nil)
    new(nil, nil, request).from_json(json)
  end

  def self.from_hash(hash, request=nil)
    obj = new(nil, nil, request)
    obj.attributes = hash
    obj
  end

  def notify_if_rate_bands_exceeded(rates)
    rates = rates.with_indifferent_access
    ADVANCE_TYPES.each do |type|
      ADVANCE_TERMS.each do |term|
        rate_data = rates[type][term]
        rate_data[:type] = type
        rate_data[:term] = term
        if rate_data[:disabled] && (rate_data[:rate_band_info][:min_threshold_exceeded] || rate_data[:rate_band_info][:max_threshold_exceeded])
          InternalMailer.exceeds_rate_band(rate_data, @request.try(:uuid), signer).deliver_now
        end
      end
    end
  end

  protected

  def terms_present?
    term.present? && type.present? && rate!.present? && amount.present?
  end

  def stock_choice_present?
    stock_choice.present?
  end

  def purchase_stock?
    ![nil, :continue].include?(stock_choice)
  end

  def clear_errors
    @errors = []
  end

  def add_error(type, code, value=nil)
    error = Error.new(type, code, value)
    @errors ||= []
    @errors << error
  end

  def no_errors_present?
    !@errors.present?
  end

  def etransact_service
    @etransact_service ||= EtransactAdvancesService.new(@request)
  end

  def rate_service
    @rate_service ||= RatesService.new(@request)
  end

  def populate_attributes_from_response(response)
    if response
      response.each do |key, value|
        self.send("#{key}=", value) unless PREVIEW_EXCLUDE_KEYS.include?(key.to_sym)
      end
    end
  end

  def perform_limit_check
    result = etransact_service.check_limits(member_id, amount, term)
    if result
      if result[:status] != 'pass'
        code = result[:status].to_sym
        add_error(:limits, code, result[code])
      end
    else
      add_error(:limits, :unknown)
    end
  end

  def perform_preview
    response = etransact_service.quick_advance_validate(member_id, amount, type, term, rate, !stock_choice_present?, signer)
    process_trade_errors(:preview, response)
    populate_attributes_from_response(response)
  end

  def perform_rate_check
    settings = etransact_service.settings
    rate_details = rate_service.rate(type, term)

    if settings && settings[:rate_stale_check]
      if rate_details
        stale_rate = rate_details[:updated_at] + settings[:rate_stale_check].seconds < Time.zone.now
        if stale_rate
          InternalMailer.stale_rate(settings[:rate_stale_check], @request.try(:request_uuid), signer).deliver_now
          add_error(:rate, :stale)
        end

        new_rate = rate_details[:rate].to_f
        old_rate = self.rate
        if new_rate != old_rate
          self.rate = new_rate
          @old_rate = old_rate
        end
      else
        add_error(:rate, :unknown)
      end
    else
      add_error(:rate, :settings)
    end
  end

  def perform_execute
    response = etransact_service.quick_advance_execute(member_id, total_amount, type, term, rate, signer)
    process_trade_errors(:execute, response)
    populate_attributes_from_response(response)
  end

  def process_trade_errors(method, response)
    if response && response[:status] && response[:status].is_a?(Array)
      unless response[:status].include?('Success')
        response[:status].each do |status|
          case status
          when 'CapitalStockError'
            add_error(method, :capital_stock)
          when 'GrossUpError', 'ExceptionError'
            add_error(method, :capital_stock_offline, status)
          when 'CreditError'
            add_error(method, :credit)
          when 'CollateralError'
            add_error(method, :collateral)
          when 'ExceedsTotalDailyLimitError'
            add_error(method, :total_daily_limit)
          else
            add_error(method, :unknown, status)
          end
        end
      end
    else
      add_error(method, :unknown)
    end
  end

  def transform_amount(amount, field)
    if amount
      if (amount.respond_to?(:match) && !amount.match(VALID_AMOUNT)) || (amount.respond_to?(:floor) && amount.floor != amount)
        raise "Invalid #{field.titleize}: #{amount}"
      end
      transformed_amount = amount
      transformed_amount = transformed_amount.dup if transformed_amount.duplicable?
      transformed_amount.try(:gsub!, ',', '')
      transformed_amount = transformed_amount.to_f
    end
    transformed_amount || amount
  end
end
