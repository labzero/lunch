namespace :corporate_communication do
  desc 'Adds namespaced classes to corproate communication email bodies and returns the html body of the email'
  task :process, [:file_location, :category] => [:environment] do |task, args|
    require 'corporate_communication/process'

    print JSON.pretty_generate(CorporateCommunication::Process.process_email(args.file_location, args.category))
  end

  desc 'Fetches and processes email found in the corporate communication inbox'
  task :fetch_and_process => [:environment] do |task, args|
    require 'corporate_communication/process'

    exit(1) unless CorporateCommunication::Process.fetch_and_process_email(JSON.parse(ENV['ANNOUNCEMENT_CATEGORY_MAPPING']))
  end
end