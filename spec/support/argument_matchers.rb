RSpec::Matchers.define :include_slice do |expected|
  match do |actual|
    ((actual.length - expected.length) + 1).times do |i|
      if actual[i..(expected.length + i - 1)] == expected
        return true
      end
    end
    false
  end
end
