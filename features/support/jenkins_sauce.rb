module JenkinsSauce
  class << self
    def jenkins_name_from_scenario(scenario)
      # Special behavior to handle Scenario Outlines
      if scenario.instance_of? ::Cucumber::Core::Ast::ExamplesTable::Row
        table = scenario.instance_variable_get(:@table)
        outline = table.instance_variable_get(:@scenario_outline)
        return "#{outline.feature.short_name} - #{outline.title} (outline example: #{scenario.name})"
      end
      scenario, feature = _scenario_and_feature_name(scenario)
      return "#{feature} - #{scenario}"
    end
  #  module_function :jenkins_name_from_scenario

    def _scenario_and_feature_name(scenario)
      scenario_name = scenario.name.split("\n").first
      feature_name = scenario.feature.name.split("\n").first
      return scenario_name, feature_name
    end
   # module_function :_scenario_and_feature_name

    def output_jenkins_log(scenario)
      job_name = JenkinsSauce.jenkins_name_from_scenario(scenario)
      driver = ::Capybara.current_session.driver
      session_id = driver.browser.session_id

      output = []
      output << "\nSauceOnDemandSessionID=#{session_id}"
      
      job_name = "job-name=#{JenkinsSauce.jenkins_name_from_scenario(scenario)}"
      output << job_name
      
      puts output.join(' ')
    end
  end
end