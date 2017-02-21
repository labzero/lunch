# Wrap modules during testing to give them access to methods ordinarily available from their callers
module MockContextHelper
  def mock_context(klass:, instance_methods:[], klass_methods:[])
    test_class = Class.new do
      include klass
      instance_methods = Array.wrap(instance_methods)
      klass_methods = Array.wrap(klass_methods)
      instance_methods.each { |method| define_method(method) { |*args| } }
      klass_methods.each { |method| define_singleton_method(method) { |*args| } }
    end
    test_class.new
  end
end