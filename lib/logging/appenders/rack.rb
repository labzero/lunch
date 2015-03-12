module Logging::Appenders

  def self.rack( *args )
    return ::Logging::Appenders::Rack if args.empty?
    ::Logging::Appenders::Rack.new(*args)
  end

  class Rack < ::Logging::Appender
    include Buffering

    def initialize( name, stream, opts = {} )
      unless stream.respond_to?(:write) && stream.respond_to?(:flush)
        raise TypeError, "expecting an Rack stream object but got '#{io.class.name}'"
      end

      @stream = stream
      @stream.flush

      super(name, opts)
      configure_buffering(opts)
    end

    def close( *args )
      return self # close is a no-op on Rack streams
    end


  private

    def canonical_write( str )
      return self if @stream.nil?
      str = str.force_encoding(encoding) if encoding and str.encoding != encoding
      @stream.write str
      self
    rescue StandardError => err
      self.level = :off
      ::Logging.log_internal {"appender #{name.inspect} has been disabled"}
      ::Logging.log_internal_error(err)
    end

  end
end