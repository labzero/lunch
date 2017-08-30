class BeneficiaryRequest
  include ActiveModel::Model
  include RedisBackedObject

  READ_ONLY_ATTRS = [:id, :owners, :request, :member_id].freeze
  ACCESSIBLE_ATTRS = [:name, :street_address, :city, :state, :zip, :care_of, :department].freeze
  REQUIRED_ATTRS = [:name, :street_address].freeze
  SERIALIZATION_EXCLUDE_ATTRS = [:request].freeze
  REDIS_EXPIRATION_KEY_PATH =  'beneficiary_request.key_expiration'

  attr_accessor *ACCESSIBLE_ATTRS
  attr_reader *READ_ONLY_ATTRS

  validates *REQUIRED_ATTRS, presence: true

  def initialize(member_id, request=ActionDispatch::TestRequest.new)
    @member_id = member_id
    @request = request
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

  def owners
    @owners ||= Set.new
  end

  def self.policy_class
    LettersOfCreditPolicy
  end

  def self.from_json(json, request)
    new(nil, request).from_json(json)
  end

end