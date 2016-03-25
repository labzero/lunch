namespace :corporate_communication do
  desc 'Adds namespaced classes to corproate communication email bodies and returns the html body of the email'
  task :process, [:file_location, :category] => [:environment] do |task, args|
    require 'corporate_communication/process'

    print JSON.pretty_generate(CorporateCommunication::Process.process_email(args.file_location, args.category))
  end

  desc 'Fetches and processes email found in the corporate communication inboxes'
  task :fetch_and_process, [:mapping] => [:environment] do |task, args|
    require 'corporate_communication/process'

    failure = false
    JSON.parse(args.mapping || ENV['ANNOUNCEMENT_CATEGORY_MAPPING']).each do |username, category|
      result = CorporateCommunication::Process.fetch_and_process_email(category, username)
      failure ||= !result
    end
    fail('at least one fetch_and_process_email call failed') if failure
  end
end