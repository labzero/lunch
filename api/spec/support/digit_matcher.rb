RSpec::Matchers.define :digits_in_range do |digits, range|
  match do |actual|
    expect(actual.to_s[range]).to eq(digits.to_s)
  end
end
