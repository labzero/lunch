require 'cucumber/formatter/junit'
class JunitWithPackage < Cucumber::Formatter::Junit

  def initialize_with_package_name(*args, &block)
    initialize_without_package_name(*args, &block)
    @package_name = ENV['CUCUMBER_JUNIT_PACKAGE_NAME']
  end

  alias_method_chain :initialize, :package_name

  private

  def end_feature(feature_data)
    @testsuite = Builder::XmlMarkup.new(:indent => 2)
    @testsuite.instruct!
    options = {
      :failures => feature_data[:failures],
      :errors => feature_data[:errors],
      :skipped => feature_data[:skipped],
      :tests => feature_data[:tests],
      :time => "%.6f" % feature_data[:time],
      :name => feature_data[:feature].name
    }
    if @package_name
      options[:package] = @package_name
      options[:name] = "#{@package_name}.#{options[:name]}"
    end
    @testsuite.testsuite(options) do
      @testsuite << feature_data[:builder].target!
    end

    write_file(feature_result_filename(feature_data[:feature].file), @testsuite.target!)
  end

  def start_feature(feature)
    raise UnNamedFeatureError.new(feature.file) if feature.name.empty?
    @current_feature_data = @features_data[feature.file]
    unless @current_feature_data[:feature]
      @current_feature_data[:feature] = feature 
      class << @current_feature_data[:builder]
        def testcase(*args, &block)
          classname = args.first.try(:[], :classname)
          package_name = ::ENV['CUCUMBER_JUNIT_PACKAGE_NAME']
          if classname && package_name
            args.first[:classname] = "#{package_name}.#{classname}"
          end
          super(*args, &block)
        end
      end
    end
  end
end
