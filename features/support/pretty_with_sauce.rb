require 'cucumber/formatter/pretty'
require_relative 'sauce_formatter'

class PrettyWithSauce < Cucumber::Formatter::Pretty
  include ::SauceFormatter
end