require 'cucumber/formatter/pretty'
require 'active_support/concern'
require_relative 'sauce_formatter'

class PrettyWithSauce < Cucumber::Formatter::Pretty
  include ::SauceFormatter
end