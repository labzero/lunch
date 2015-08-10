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