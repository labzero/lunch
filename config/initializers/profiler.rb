if ENV['PROFILE_MODE'] == 'true'
  require 'ruby-prof'
  require 'singleton'
  class Profiler
    include Singleton

    def logger
      @logger ||= Logger.new(File.join(self.class.log_directory, 'performance.log'))
    end

    def profile
      RubyProf.start
      yield
      results = RubyProf.stop
    end

    def time(name)
      start = Time.now
      yield
      time = Time.now - start
      logger.debug("%s - %f" % [name, time])
    end

    def self.profile(*args, &block)
      self.instance.profile(*args, &block)
    end

    def self.time(*args, &block)
      self.instance.time(*args, &block)
    end

    def self.middleware(dir='profiles')
      [
        Rack::RubyProf,
        path: File.join(log_directory, dir), printers: {
          ::RubyProf::GraphHtmlPrinter => 'graph.html',
          ::RubyProf::CallStackPrinter => 'call_stack.html',
          ::RubyProf::CallTreePrinter => 'call_tree.cachegrind'
        }
      ]
    end

    def self.log_directory
      dir = Rails.root.join('log') if defined?(Rails)
      dir ||= File.expand_path('../../log/', __dir__)
    end
  end

  if defined?(RestClient)
    class RestClient::Resource
      def get_with_profile(*args, &block)
        exception = nil
        result = nil
        Profiler.time("GET #{self.url}") do
          begin
            result = get_without_profile(*args, &block)
          rescue Exception => e
            exception = e
          end
        end
        raise exception if exception
        result
      end

      def post_with_profile(*args, &block)
        exception = nil
        result = nil
        Profiler.time("POST #{self.url}") do
          begin
            result = post_without_profile(*args, &block)
          rescue Exception => e
            exception = e
          end
        end
        raise exception if exception
        result
      end

      def put_with_profile(*args, &block)
        exception = nil
        result = nil
        Profiler.time("PUT #{self.url}") do
          begin
            result = put_without_profile(*args, &block)
          rescue Exception => e
            exception = e
          end
        end
        raise exception if exception
        result
      end

      def delete_with_profile(*args, &block)
        exception = nil
        result = nil
        Profiler.time("DELETE #{self.url}") do
          begin
            result = delete_without_profile(*args, &block)
          rescue Exception => e
            exception = e
          end
        end
        raise exception if exception
        result
      end

      alias_method_chain :get, :profile
      alias_method_chain :put, :profile
      alias_method_chain :post, :profile
      alias_method_chain :delete, :profile
    end
  end
end