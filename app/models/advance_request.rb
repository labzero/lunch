class AdvanceRequest

  class Error
    attr_reader :type, :code, :value

    def initialize(type, code, value=nil)
      @type = type
      @code = code
      @value = value
    end

    def inspect
      "<#{self.class}:#{object_id} type='#{type}' code='#{code}' value='#{value}'>"
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
  LONG_ADVANCE_TERMS = ADVANCE_TERMS[8..-1].freeze

  READONLY_ATTRS = [:signer, :timestamp, :checked_stock, :member_id, :old_rate, :owners, :request].freeze
  REQUEST_PARAMETERS = [
    :exception_message, :cumulative_stock_required,
    :current_trade_stock_required, :pre_trade_stock_required, :net_stock_required, :gross_amount,
    :gross_cumulative_stock_required, :gross_current_trade_stock_required,
    :gross_pre_trade_stock_required, :gross_net_stock_required,
    :interest_day_count, :payment_on, :funding_date, :maturity_date, :initiated_at,
    :confirmation_number, :authorized_amount, :credit_max_amount, :collateral_max_amount,
    :collateral_authorized_amount, :trade_date, :allow_grace_period
  ].freeze
  CORE_PARAMETERS = [:type, :rates, :term, :amount, :rate, :stock_choice].freeze
  PREVIEW_EXCLUDE_KEYS = [:advance_amount, :advance_rate, :advance_type, :advance_term, :status].freeze
  PARAMETER_ORDER = [:rates, :term, :type, :amount].freeze
  SERIALIZATION_EXCLUDE_ATTRS = [:request].freeze

  VALID_AMOUNT = /\A[0-9,]+(\.0?0?)?\z/i.freeze
  LOG_PREFIX = "  \e[36m\033[1mREDIS\e[0m ".freeze

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

  def self.policy_class
    AdvancePolicy
  end

  def initialize(member_id, signer, request=nil)
    @member_id = member_id
    @signer = signer
    @request = request
  end

  def id
    @id ||= SecureRandom.uuid
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

    if timestamp.present? && (Time.zone.now - timestamp >= timeout)
      perform_rate_check
      rate_changed = rate_changed?
      timestamp! unless rate_changed
      rate_changed
    else
      false
    end
  end

  def rate_for(term, type)
    rates_for_type = rates[type.to_sym]
    raise "Rate not found for type: #{type}" if rates_for_type.nil?
    rates_for_term = rates_for_type[term.to_sym]
    raise "Rate not found for term: #{term}" if rates_for_term.nil?
    rates_for_term[:rate].to_f
  end

  def rate_for!(term, type)
    self.rate = rate_for(term, type)
  end

  def maturity_date_for(term, type)
    rates_for_type = rates[type.to_sym]
    raise "Rate not found for type: #{type}" if rates_for_type.nil?
    rates_for_term = rates_for_type[term.to_sym]
    raise "Rate not found for term: #{term}" if rates_for_term.nil?
    rates_for_term[:maturity_date].try(:to_date)
  end

  def maturity_date_for!(term, type)
    self.maturity_date = maturity_date_for(term, type)
  end

  def maturity_date=(value)
    @maturity_date = value.try(:to_date)
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
      notify_if_rate_bands_exceeded
    end
    @rates 
  end

  def term=(term)
    term = term.try(:to_sym)
    raise ArgumentError.new("Unknown Advance Term: #{term}") unless ADVANCE_TERMS.include?(term)
    old_term = @term
    @term = term
    if old_term != term && type
      reset_stock_choice!
      rate_for!(self.term, type)
      maturity_date_for!(self.term, type)
    end
  end

  def type=(type)
    type = type.try(:to_sym)
    raise ArgumentError.new("Unknown Advance Type: #{type}") unless ADVANCE_TYPES.include?(type)
    old_type = @type
    @type = type
    if old_type != type && term
      reset_stock_choice!
      rate_for!(term, self.type)
      maturity_date_for!(term, self.type)
    end
  end

  def amount=(amount)
    old_amount = @amount
    @amount = transform_amount(amount, :amount)
    reset_stock_choice! if old_amount != @amount
  end

  def gross_amount=(amount)
    @gross_amount = transform_amount(amount, :gross_amount)
  end

  def stock_choice=(choice)
    choice = choice.to_sym if choice
    raise "Unknown Stock Choice: #{choice}" if choice && !STOCK_CHOICES.include?(choice)
    @stock_choice = choice
  end

  def allow_grace_period=(allowed)
    @allow_grace_period = !!allowed
  end
  
  def reset_stock_choice!
    %w(@stock_choice @cumulative_stock_required @current_trade_stock_required @pre_trade_stock_required
      @net_stock_required @gross_amount @gross_cumulative_stock_required @gross_current_trade_stock_required
      @gross_pre_trade_stock_required @gross_net_stock_required).each do |ivar|
        instance_variable_set(ivar, nil)
      end
  end

  def initiated_at=(datetime)
    @initiated_at = datetime.try(:to_datetime)
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

  def term_type
    case term
    when :overnight, :open
      :vrc
    when nil
      nil
    else
      :frc
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

  def human_payment_on
    case payment_on
      when 'Maturity'               then I18n.t('dashboard.quick_advance.table.maturity')
      when 'MonthEndOrRepayment'    then I18n.t('dashboard.quick_advance.table.monthendorrepayment')
      when 'Repayment'              then I18n.t('dashboard.quick_advance.table.repayment')
      when 'SemiannualAndRepayment' then I18n.t('dashboard.quick_advance.table.semiannualandrepayment')
      else raise ArgumentError.new("Unrecognized value for payment_on: #{payment_on}")
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
    process_attribute = Proc.new do |key, value|
      case key.to_sym
      when *SERIALIZATION_EXCLUDE_ATTRS
        raise "illegal attribute: #{key}"
      when :current_state
        aasm.current_state = value.to_sym
      when :rates
        self.rates = value.with_indifferent_access
      when :id
        @id = value
      when :timestamp
        @timestamp = value.to_datetime
      when :owners
        @owners = value.to_set
      when *READONLY_ATTRS
        instance_variable_set("@#{key}", value)
      when *(REQUEST_PARAMETERS + CORE_PARAMETERS)
        send("#{key}=", value)
      else
        raise "unknown attribute: #{key}"
      end
    end
    indifferent_hash = hash.with_indifferent_access
    keys = indifferent_hash.keys.collect(&:to_sym)
    ordered_keys = PARAMETER_ORDER & keys
    other_keys = indifferent_hash.keys.collect(&:to_sym) - ordered_keys
    (ordered_keys + other_keys).each do |key|
      process_attribute.call(key, indifferent_hash[key])
    end
  end

  def attributes
    attrs = {}
    (READONLY_ATTRS + REQUEST_PARAMETERS + CORE_PARAMETERS + [:id] - SERIALIZATION_EXCLUDE_ATTRS).each do |key|
      attrs[key] = nil if send(key)
    end
    attrs[:current_state] = current_state
    attrs
  end

  def save
    save_result = !!redis_value.set(to_json)
    save_result = !!(redis_value.expire(Rails.configuration.x.advance_request.key_expiration)) if save_result
    log{"AdvanceRequest:#{id} #{save_result ? 'saved' : 'save failed'}."}
    save_result
  end

  def ttl
    redis_value.ttl
  end

  def inspect
    "<#{self.class}:#{id} state='#{current_state}' term='#{term}' type='#{type}' rate='#{rate}' amount='#{amount}' stock_choice='#{stock_choice}' errors=#{errors.inspect}>"
  end

  def owners
    @owners ||= Set.new
  end

  def self.from_json(json, request=nil)
    new(nil, nil, request).from_json(json)
  end

  def self.from_hash(hash, request=nil)
    obj = new(nil, nil, request)
    obj.attributes = hash
    obj
  end

  def self.find(id, request=nil)
    value = redis_value(id)
    raise ActiveRecord::RecordNotFound if value.nil?
    obj = from_json(value.value, request)
    value.expire(Rails.configuration.x.advance_request.key_expiration)
    log{"AdvanceRequest.find(#{id}) #{obj ? 'succeded' : 'failed'}."}
    obj
  end

  def self.redis_key(id)
    "#{self.name}:#{id}"
  end

  def self.redis_value(id)
    Redis::Value.new(redis_key(id))
  end

  def self.log(level = :info, &message_block)
    Rails.logger.send(level) { LOG_PREFIX + message_block.call.to_s }
  end

  protected

  def log(level = :info, &message_block)
    self.class.log(level, &message_block)
  end

  def redis_value
    @redis_value ||= self.class.redis_value(id)
  end

  def notify_if_rate_bands_exceeded
    return unless @rates
    ADVANCE_TYPES.each do |type|
      ADVANCE_TERMS.each do |term|
        rate_data = @rates[type][term].dup
        rate_data[:type] = type
        rate_data[:term] = term
        if rate_data[:disabled] && !rate_data[:end_of_day] && (rate_data[:rate_band_info][:min_threshold_exceeded] || rate_data[:rate_band_info][:max_threshold_exceeded])
          InternalMailer.exceeds_rate_band(rate_data, request.try(:uuid), signer).deliver_now
        end
      end
    end
  end

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
    @etransact_service ||= EtransactAdvancesService.new(request)
  end

  def rate_service
    @rate_service ||= RatesService.new(request)
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
    response = etransact_service.quick_advance_validate(member_id, amount, type, term, rate, !stock_choice_present?, signer, maturity_date, allow_grace_period)
    process_trade_errors(:preview, response)
    populate_attributes_from_response(response)
  end

  def perform_rate_check
    return if aasm.current_event == :execute
    settings = etransact_service.settings
    rate_details = rate_service.rate(type, term)

    if settings && settings[:rate_stale_check]
      if rate_details
        stale_rate = rate_details[:updated_at] + settings[:rate_stale_check].seconds < Time.zone.now
        if stale_rate
          InternalMailer.stale_rate(settings[:rate_stale_check], request.try(:request_uuid), signer).deliver_now
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
    response = etransact_service.quick_advance_execute(member_id, total_amount, type, term, rate, signer, maturity_date, allow_grace_period)
    process_trade_errors(:execute, response)
    populate_attributes_from_response(response)
    if no_errors_present? && LONG_ADVANCE_TERMS.include?(term)
      InternalMailer.long_term_advance(self).deliver_now
    end
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
          when 'DisabledProductError'
            add_error(method, :disabled_product)
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
        raise ArgumentError.new("Invalid #{field.titleize}: #{amount}")
      end
      transformed_amount = amount
      transformed_amount = transformed_amount.dup if transformed_amount.duplicable?
      transformed_amount.try(:gsub!, ',', '')
      transformed_amount = transformed_amount.to_f
    end
    transformed_amount || amount
  end
end
