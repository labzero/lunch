namespace :process do
  desc "Adds namespaced classes to corporate communication email bodies and returns the html body of the email"
  task :corp_com, [:file_location, :category] do |task, args|
    require 'process_corp_com'

    print JSON.pretty_generate(ProcessCorpCom.process_email(args.file_location, args.category))
  end
end