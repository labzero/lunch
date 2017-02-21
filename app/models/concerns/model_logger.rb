module ModelLogger
  extend ActiveSupport::Concern

  protected

  def log(level = :info, &message_block)
    self.class.log(level, &message_block)
  end

  module ClassMethods
    def log(level = :info, &message_block)
      Rails.logger.send(level) { self::LOG_PREFIX + message_block.call.to_s }
    end
  end
end