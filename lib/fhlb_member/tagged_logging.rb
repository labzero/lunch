module FhlbMember
  module TaggedLogging
    include ActiveSupport::TaggedLogging

    module Formatter
      include ActiveSupport::TaggedLogging::Formatter
      def tags_text
        tags = current_tags
        if tags.any?
          tags.collect do |tag|
            tag = tag.call if tag.respond_to?(:call)
            "[#{tag}] "
          end.join
        end
      end
    end

    def self.new(logger)
      # Ensure we set a default formatter so we aren't extending nil!
      logger.formatter ||= ActiveSupport::Logger::SimpleFormatter.new
      logger.formatter.extend Formatter
      logger.extend(self)
    end
  end
end