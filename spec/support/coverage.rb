module FhlbMember
  module Coverage
    class MergedFormatter
      def format(result)
         SimpleCov::Formatter::HTMLFormatter.new.format(result)
         SimpleCov::Formatter::RcovFormatter.new.format(result)
      end
    end
    def self.simplecov_init(command_name)
      require 'simplecov'
      require 'simplecov-rcov'
      root_dir = File.expand_path(File.join('..', '..', '..'), __FILE__)
      SimpleCov.formatter = FhlbMember::Coverage::MergedFormatter
      SimpleCov.use_merging
      SimpleCov.command_name command_name
      SimpleCov.root root_dir
      SimpleCov.coverage_dir File.join(root_dir, 'coverage')
      SimpleCov.add_group 'API Models', 'api/models'
      SimpleCov.add_group 'API Endpoints', ['api/services', 'api/mapi.rb']
      SimpleCov.add_group 'API Misc', 'api/shared'
      SimpleCov.add_group 'Jobs', 'app/jobs'
      SimpleCov.add_group 'Policies', 'app/policies'
      SimpleCov.add_group 'Services', 'app/services'
      SimpleCov.add_filter 'api/spec'
      SimpleCov.minimum_coverage ENV['SIMPLECOV_MINIMUM_COVERAGE'] ? ENV['SIMPLECOV_MINIMUM_COVERAGE'].to_i : 98
      SimpleCov.start 'rails'
    end
  end
end