namespace :ci do
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