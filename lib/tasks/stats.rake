namespace :stats do
  desc 'Fetches a list of extranet users who have logged in by institution.'
  task :extranet_logins => :environment do
    Stats.extranet_logins.each do |member, users|
      puts "#{member}:"
      puts ''
      puts users
      puts ''
    end
  end
end