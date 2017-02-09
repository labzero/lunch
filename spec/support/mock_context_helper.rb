# Wrap modules during testing to give them access to methods ordinarily available from their callers
module MockContextHelper
  def mock_context(helper_klass, methods)
    test_class = Class.new do
      include helper_klass
      methods.each { |method| define_method(method) {} }
    end
    test_class.new
  end
end