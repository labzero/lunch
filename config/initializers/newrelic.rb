NewRelic::Agent.add_instrumentation(Rails.root.join('lib', 'new_relic', 'instrumentation', '**', '*.rb')) if defined?(NewRelic::Agent)
