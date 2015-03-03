namespace :process do
  task :maintenance, [:file_location] => :environment do |task, args|
    controller = ErrorController.new
    controller.request = ActionDispatch::TestRequest.new
    controller.response = ActionDispatch::TestResponse.new
    html = controller.maintenance.first
    if args.file_location
      File.write(args.file_location, html)
    else
      STDOUT.print html
    end
  end
end