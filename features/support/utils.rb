def parallel_test_number
  ENV['TEST_ENV_NUMBER'] == '' ? 1 : ENV['TEST_ENV_NUMBER'].try(&:to_i)
end

def run_name
  [ENV['JOB_NAME'] || "Local Dev (#{`whoami`.strip})", ENV['BUILD_NUMBER'], parallel_test_number].compact.join('-')
end