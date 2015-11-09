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

    module Helpers

      def profile_method(method, log, *args, &block)
        exception = nil
        result = nil
        Profiler.time(log) do
          begin
            result = send(method, *args, &block)
          rescue Exception => e
            exception = e
          end
        end
        raise exception if exception
        result
      end

    end
  end

  if defined?(RestClient)
    class RestClient::Resource
      include Profiler::Helpers

      def get_with_profile(*args, &block)
        profile_method(:get_without_profile, "GET #{self.url}", *args, &block)
      end

      def post_with_profile(*args, &block)
        profile_method(:post_without_profile, "POST #{self.url}", *args, &block)
      end

      def put_with_profile(*args, &block)
        profile_method(:put_without_profile, "PUT #{self.url}", *args, &block)
      end

      def delete_with_profile(*args, &block)
        profile_method(:delete_without_profile, "DELETE #{self.url}", *args, &block)
      end

      alias_method_chain :get, :profile
      alias_method_chain :put, :profile
      alias_method_chain :post, :profile
      alias_method_chain :delete, :profile
    end
  end

  if defined?(Net::LDAP)
    class Net::LDAP::Connection
      include Profiler::Helpers

      def initialize_with_profile(*args, &block)
        profile_method(:initialize_without_profile, "LDAP CONNECT: #{args}", *args, &block)
      end

      def add_with_profile(*args, &block)
        profile_method(:add_without_profile, "LDAP ADD: #{args}", *args, &block)
      end

      def bind_with_profile(*args, &block)
        profile_method(:bind_without_profile, "LDAP BIND: #{args}", *args, &block)
      end

      def close_with_profile(*args, &block)
        profile_method(:close_without_profile, "LDAP CLOSE", *args, &block)
      end

      def delete_with_profile(*args, &block)
        profile_method(:delete_without_profile, "LDAP DELETE: #{args}", *args, &block)
      end

      def modify_with_profile(*args, &block)
        profile_method(:modify_without_profile, "LDAP MODIFY: #{args}", *args, &block)
      end

      def rename_with_profile(*args, &block)
        profile_method(:rename_without_profile, "LDAP RENAME: #{args}", *args, &block)
      end

      def search_with_profile(*args, &block)
        profile_method(:search_without_profile, "LDAP SEARCH: #{args}", *args, &block)
      end

      def setup_encryption_with_profile(*args, &block)
        profile_method(:setup_encryption_without_profile, "LDAP SSL: #{args}", *args, &block)
      end


      alias_method_chain :initialize, :profile
      alias_method_chain :add, :profile
      alias_method_chain :bind, :profile
      alias_method_chain :close, :profile
      alias_method_chain :delete, :profile
      alias_method_chain :modify, :profile
      alias_method_chain :rename, :profile
      alias_method_chain :search, :profile
      alias_method_chain :setup_encryption, :profile
    end
  end
end