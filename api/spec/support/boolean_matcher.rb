RSpec::Matchers.define :be_boolean do
  match do |actual|
    expect( actual ).to satisfy { |x| x.is_a?( TrueClass ) || x.is_a?( FalseClass ) }
  end
end
