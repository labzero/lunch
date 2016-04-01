class RakeTaskJob < FhlbJob
  def perform(task_name, *args)
    require 'rake'
    rake = Rake.application
    rake.init
    rake.load_rakefile
    task = ::Rake::Task[task_name]
    task.reenable
    task.invoke(*args)
  end
end