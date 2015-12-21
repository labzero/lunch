namespace :ci do
  desc "Sets up the test environment and runs the tests and static analysis"
  task :build => ['spec', 'spec:api', 'ci:brakeman']
  
  desc "Run Brakeman"
  task :brakeman do
    require 'brakeman'
    Brakeman.run :app_path => '.', :output_files => ['brakeman.html', 'brakeman.tabs', 'brakeman.txt'], :quiet => false
    File.foreach 'brakeman.txt' do |line|
      puts line
    end
    File.unlink('brakeman.txt')
  end

  desc 'Launch SauceConnect'
  task :sauce_connect do
    exec "sc -k #{ENV['SAUCE_ACCESS_KEY']} -u #{ENV['SAUCE_USERNAME']}"
  end

  namespace :cucumber do
    desc 'Runs the cukes in parallel'
    task :parallel do
      ::Rake::Task['ci:cucumber:parallel:base'].invoke
    end

    namespace :parallel do
      task :base, [:test_options, :runtime_log_file] do |task, args|
        pid = fork do
          runner_count = ENV['CUCUMBER_RUNNER_COUNT'] || 6
          runtime_log_file = args.runtime_log_file || 'tmp/parallel_runtime_cucumber.log'
          runtime_log = File.exist?(runtime_log_file) ? "--group-by runtime --runtime-log '#{runtime_log_file}'" : nil
          test_options = ["--out #{runtime_log_file}", args.test_options, ENV['CUCUMBER_TEST_OPTIONS']].reject { |s| s.nil? || s.length == 0 }.join(' ')
          cmd = "RAILS_ENV=test parallel_test features --type cucumber -n #{runner_count} #{runtime_log} --serialize-stdout --test-options '#{test_options}'"
          puts cmd
          Bundler.clean_exec cmd
        end
        Process.wait(pid)
        exit $?.exitstatus
      end

      desc 'Runs the smoke cukes in parallel'
      task :smokes do
        ::Rake::Task['ci:cucumber:parallel:base'].invoke('--tags @smoke --tags ~@local-only', 'tmp/parallel_runtime_cucumber_smokes.log')
      end
    end
  end
end

namespace :spec do
  desc "Runs the API specs"
  task :api  do
    orig_dir = Dir.pwd
    Dir.chdir('api')
    command = "rspec #{ENV['SPEC']}"
    begin
      puts command if verbose
      success = system(command)
    rescue
      puts failure_message if failure_message
    ensure
      Dir.chdir(orig_dir)
    end

    unless success
      $stderr.puts "#{command} failed"
      exit $?.exitstatus
    end
  end
end
# RSpec::Core::RakeTask.new("spec:api") do |t|
#   t.pattern = File.join('api', RSpec::Core::RakeTask::DEFAULT_PATTERN)
# end