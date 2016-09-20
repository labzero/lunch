require 'active_support/concern'
require 'active_support/core_ext/module'

unless defined? SauceFormatter
  module SauceFormatter
    extend ::ActiveSupport::Concern

    included do
      def sauce_labs?
        !@dry_run && ::Capybara.current_session.driver.options[:url] == SAUCE_CONNECT_URL
      end

      def initialize_with_sauce(step_mother, io, options)
        @dry_run = options[:dry_run]
        @failed_scenarios = []
        @passed_scenarios = []
        @sauce_job_id = nil
        @run_start_time = nil
        @scenario_start_time = nil
        @scenario = nil
        @last_step_result = nil
        @scenario_failed = false
        initialize_without_sauce(step_mother, io, options)
      end

      def before_test_case_with_sauce(test_case, &block)
        start_sauce_run
        before_test_case_without_sauce(test_case, &block)
      end

      def after_feature_element_with_sauce(scenario, &block)
        end_sauce_scenario(scenario)
        after_feature_element_without_sauce(scenario, &block)
      end

      def before_test_step_with_sauce(step, &block)
        unless is_hook_step?(step) || is_backround_step?(step)
          scenario = step.source.find { |node| node.is_a?(Cucumber::Core::Ast::ExamplesTable::Row) || node.is_a?(Cucumber::Core::Ast::Scenario) }
          start_sauce_scenario(scenario)
        end
        before_test_step_without_sauce(step, &block)
      end

      def after_test_step_with_sauce(step, result, &block)
        @last_step_result = result
        @scenario_failed ||= result.ok?
        after_test_step_without_sauce(step, result, &block)
      end

      def done_with_sauce(&block)
        if sauce_labs?
          require 'sauce_whisk'
          begin
            job = SauceWhisk::Jobs.fetch @sauce_job_id
            format_scenario_data = ->(entry) do
              {
                location: human_location(entry[:scenario]),
                start_time: entry[:runtime].first.round(1),
                end_time: entry[:runtime].last.round(1)
              }
            end
            job.passed = @failed_scenarios.empty?
            job.custom_data = {passed: @passed_scenarios.collect(&format_scenario_data), failed: @failed_scenarios.collect(&format_scenario_data) }
            job.save
          rescue RestClient::Exception => e
            sauce_print("Failed to annotate Sauce job: #{e}")
          end
        end
        done_without_sauce(&block)
      end

      [:done, :after_feature_element, :before_test_case, :before_test_step, :after_test_step].each do |method|
        unless method_defined?(method)
          define_method(method, ->(*args) {} )
        end
        alias_method_chain method, :sauce
      end
      alias_method_chain :initialize, :sauce

      private

      def now
        if Time.respond_to?(:zone)
          (Time.zone || Time).now
        else
          Time.now
        end
      end

      def debug(name, *args)
        STDOUT.puts("#{name}: " + summarize(*args).to_json)
      end

      def summarize(*args)
        args.collect do |arg|
          case arg
          when String, Symbol, Fixnum, nil, true, false
            arg
          when Array
            summarize(*arg)
          when Cucumber::Core::Test::Step
            arg.inspect
          else
            arg.class.name
          end
        end
      end

      def is_example_step?(step)
        step.source.find { |node| node.is_a?(Cucumber::Core::Ast::ExamplesTable::Row) }.present?
      end

      def is_scenario_step?(step)
        step.source.find { |node| node.is_a?(Cucumber::Core::Ast::Scenario) }.present?
      end

      def is_backround_step?(step)
        step.source.find { |node| node.is_a?(Cucumber::Core::Ast::Background) }.present?
      end

      def is_hook_step?(step)
        step.source.find { |node| node.is_a?(Cucumber::Hooks) }.present?
      end

      def start_sauce_run
        unless @dry_run || @run_start_time
          @run_start_time = now
          ::Capybara.current_session.driver.visit('about:blank')
        end
      end

      def start_sauce_scenario(scenario)
        if !@dry_run && @scenario != scenario
          end_sauce_scenario(@scenario) if @scenario
          @scenario_start_time = now
          @scenario = scenario
        end
      end

      def end_sauce_scenario(scenario)
        unless @dry_run
          scenario_end_time = now
          @sauce_job_id ||= ::Capybara.current_session.driver.browser.session_id if sauce_labs?
          unless @last_step_result.nil? || @last_step_result.is_a?(Cucumber::Core::Test::Result::Skipped)
            runtime_range = ((@scenario_start_time - @run_start_time))..((scenario_end_time - @run_start_time))
            if @scenario_failed
              @failed_scenarios << {scenario: scenario, runtime: runtime_range}
            else
              @passed_scenarios << {scenario: scenario, runtime: runtime_range}
            end
            sauce_print "started at: #{runtime_range.first.round(1)}, finished at: #{runtime_range.last.round(1)} (times approximate)"
          end
          @last_step_result = nil
          @scenario_start_time = nil
          @scenario = nil
          @scenario_failed = false
        end
      end

      def sauce_print(message)
        if self.respond_to?(:print_message)
          print_message(message)
        else
          puts(message)
        end
      end
    end
  end
end