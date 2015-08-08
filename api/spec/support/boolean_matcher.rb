RSpec::Matchers.define :be_boolean do
  match do |actual|
    actual.should satisfy { |x| x == true || x == false }
  end
end