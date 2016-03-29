class RakeTaskJob < FhlbJob
  def perform(task, *args)
    require 'rake'
    rake = Rake.application
    rake.init
    rake.load_rakefile
    ::Rake::Task[task].execute(args)
  end
end