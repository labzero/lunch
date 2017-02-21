module RedisBackedObject
  extend ActiveSupport::Concern
  include ActiveModel::Serializers::JSON
  include ModelLogger

  LOG_PREFIX = "  \e[36m\033[1mREDIS\e[0m ".freeze

  def save
    save_result = !!redis_value.set(to_json)
    save_result = !!(redis_value.expire(self.class.redis_expiration)) if save_result
    log{"#{self.class.name}:#{id} #{save_result ? 'saved' : 'save failed'}."}
    save_result
  end

  protected

  def redis_value
    @redis_value ||= self.class.redis_value(id)
  end

  module ClassMethods
    def find(id, request=nil)
      value = redis_value(id)
      raise ActiveRecord::RecordNotFound if value.nil?
      obj = from_json(value.value, request)
      value.expire(redis_expiration)
      log{"#{self.name}.find(#{id}) #{obj ? 'succeeded' : 'failed'}."}
      obj
    end

    def redis_value(id)
      Redis::Value.new(redis_key(id))
    end

    def redis_expiration
      Rails.configuration.x.instance_eval(self::REDIS_EXPIRATION_KEY_PATH)
    end

    def redis_key(id)
      "#{self.name}:#{id}"
    end

  end
end