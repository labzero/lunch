if defined?(Net::LDAP)

  class Net::LDAP
    include ::NewRelic::Agent::MethodTracer

    [
      :add, :bind, :bind_as, :delete, :get_operation_result, :modify, :open,
      :rename, :search
    ].each do |method|
      add_method_tracer method
    end
  end
  
end