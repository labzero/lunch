module FhlbMember
  class FlipperActor
    attr_reader :flipper_id
    def initialize(flipper_id)
      raise ArgumentError.new('flipper_id must be present') unless flipper_id
      @flipper_id = flipper_id
    end

    def self.wrap(actor)
      if actor.respond_to?(:flipper_id)
        actor
      else
        self.new(actor)
      end
    end
  end
end
