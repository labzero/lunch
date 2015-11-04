def parallel_test_number
  ENV['TEST_ENV_NUMBER'] == '' ? 1 : ENV['TEST_ENV_NUMBER'].try(&:to_i)
end

def run_name
  [ENV['JOB_NAME'] || "Local Dev (#{`whoami`.strip})", ENV['BUILD_NUMBER'], parallel_test_number].compact.join('-')
end

def kill_background_process(thread, stdin, kill_signal='INT')
  Process.kill(kill_signal, thread.pid) rescue Errno::ESRCH
  stdin.close
  thread.value # wait for the thread to finish
end
