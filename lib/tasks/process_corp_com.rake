namespace :process do
  desc "Adds namespaced classes to corporate communication email bodies and returns the html body of the email"
  task :corp_com, [:file_location] do |task, args|
    require 'process_corp_com'

    print ProcessCorpCom.process_email_html(args.file_location)
  end
end