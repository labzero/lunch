RSpec::Matchers.define :be_boolean do
  match do |actual|
    actual.should satisfy { |x| x.is_a? TrueClass || x.is_a? FalseClass }
  end
end
