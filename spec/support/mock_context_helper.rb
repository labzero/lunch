# Wrap modules during testing to give them access to methods ordinarily available from their callers
module MockContextHelper
  def mock_context(module_arg, instance_methods:[], class_methods:[])
    test_class = Class.new do
      include module_arg
      instance_methods = Array.wrap(instance_methods)
      class_methods = Array.wrap(class_methods)
      instance_methods.each { |method| define_method(method) { |*args| } }
      class_methods.each { |method| define_singleton_method(method) { |*args| } }
    end
    test_class.new
  end
end