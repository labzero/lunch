class EarlyShutoffRequest
  include ActiveModel::Model
  include RedisBackedObject

  TIME_24_HOUR_FORMAT = /\A[0-1]\d[0-5]\d\z|\A2[0-3][0-5]\d\z/
  REDIS_EXPIRATION_KEY_PATH =  'early_shutoff_request.key_expiration'
  DEFAULT_FRC_SHUTOFF_TIME = '1200'
  DEFAULT_VRC_SHUTOFF_TIME = '1400'

  REQUIRED_ATTRS = [:early_shutoff_date, :frc_shutoff_time, :vrc_shutoff_time, :day_of_message].freeze
  OPTIONAL_ATTRS = [:day_before_message].freeze
  ACCESSIBLE_ATTRS = REQUIRED_ATTRS + OPTIONAL_ATTRS
  READ_ONLY_ATTRS = [:id, :owners, :request].freeze
  SERIALIZATION_EXCLUDE_ATTRS = [:request].freeze

  attr_accessor *ACCESSIBLE_ATTRS
  attr_reader *READ_ONLY_ATTRS

  def initialize(request=ActionDispatch::TestRequest.new)
    @request = request
    @early_shutoff_date = Time.zone.today
    @frc_shutoff_time = DEFAULT_FRC_SHUTOFF_TIME
    @vrc_shutoff_time = DEFAULT_VRC_SHUTOFF_TIME
  end

  def self.policy_class
    WebAdminPolicy
  end

  def self.from_json(json, request)
    new(request).from_json(json)
  end

  def id
    @id ||= SecureRandom.uuid
  end

  def attributes
    attrs = {}
    (ACCESSIBLE_ATTRS + READ_ONLY_ATTRS - SERIALIZATION_EXCLUDE_ATTRS).each do |key|
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

  def frc_shutoff_time=(time)
    time = time.to_s
    if time.match(TIME_24_HOUR_FORMAT)
      @frc_shutoff_time = time
    else
      raise ArgumentError.new('frc_shutoff_time must be a 4-digit, 24-hour time representation with values between `0000` and `2359`')
    end
  end

  def vrc_shutoff_time=(time)
    time = time.to_s
    if time.match(TIME_24_HOUR_FORMAT)
      @vrc_shutoff_time = time
    else
      raise ArgumentError, 'vrc_shutoff_time must be a 4-digit, 24-hour time representation with values between `0000` and `2359`'
    end
  end

  def frc_shutoff_time_hour
    frc_shutoff_time[0,2]
  end

  def frc_shutoff_time_minute
    frc_shutoff_time[2,2]
  end

  def vrc_shutoff_time_hour
    vrc_shutoff_time[0,2]
  end

  def vrc_shutoff_time_minute
    vrc_shutoff_time[2,2]
  end

  def owners
    @owners ||= Set.new
  end

  def day_of_message_simple_format
    simple_format_for(day_of_message) if day_of_message
  end

  def day_before_message_simple_format
    simple_format_for(day_before_message) if day_before_message
  end

  private

  def simple_format_for(text)
    text.gsub(/(\r\n)+/, "\n\n").strip
  end

end