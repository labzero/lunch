require 'cucumber/formatter/junit'
class JunitWithPackage < Cucumber::Formatter::Junit
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
    options[:package] = ENV['CUCUMBER_JUNIT_PACKAGE_NAME'] if ENV['CUCUMBER_JUNIT_PACKAGE_NAME']
    @testsuite.testsuite(options) do
      @testsuite << feature_data[:builder].target!
    end

    write_file(feature_result_filename(feature_data[:feature].file), @testsuite.target!)
  end
end
