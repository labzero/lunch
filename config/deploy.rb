# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'member'
set :repo_url, 'git@github.com:labzero/fhlb-member.git'

set :deploy_to, '/usr/local/member'

set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml .env}

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
    on roles(:api), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('api/tmp/restart.txt')
    end
    invoke 'resque_pool:restart'
  end

  desc 'Creates API directories'
  task :missing_dirs do
    on roles(:api) do
      execute :mkdir, '-p', release_path.join('api/tmp')
    end
  end

  desc 'Clear the tmp directory'
  task :clear_tmp do
    on roles(:web) do
      within release_path do
        execute :rake, 'tmp:clear'
      end
    end
  end

  desc 'Runs rake db:seed'
  task :seed => [:set_rails_env] do
    on primary fetch(:migration_role) do
      info '[deploy:seed] Run `rake db:seed`'
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "db:seed"
        end
      end
    end
  end

  desc 'Builds the maintenance site'
  task :compile_maintenance => [:set_rails_env] do
    on release_roles(fetch(:assets_roles)) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, "process:maintenance[#{release_path}/public/maintenance.html]"
        end
      end
    end
  end

  before :compile_assets, :clear_tmp
  after :compile_assets, :compile_maintenance
  before :publishing, :missing_dirs
  after :publishing, :restart
  after :migrate, :seed

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end

namespace :resque_pool do
  desc 'Starts the resque-pool daemon'
  task :start do
    on roles(:resque), in: :sequence, wait: 5 do
      sudo :start, 'resque-pool'
    end
  end
  desc 'Stops the resque-pool daemon'
  task :stop do
    on roles(:resque), in: :sequence, wait: 5 do
      sudo :stop, 'resque-pool'
    end
  end
  desc 'Restarts the resque-pool daemon'
  task :restart do
    on roles(:resque), in: :sequence, wait: 5 do
      begin
        sudo :start, 'resque-pool'
      rescue SSHKit::Command::Failed
        sudo :stop, 'resque-pool'
        sudo :start, 'resque-pool'
      end
    end
  end
  desc 'Reloads the resque-pool daemon, which gives it all new children but leaves the partent process untouched'
  task :reload do
    on roles(:resque), in: :sequence, wait: 5 do
      sudo :reload, 'resque-pool'
    end
  end
end

namespace :cluster do
  namespace :logs do
    desc 'Fetches the logfiles from the cluster in question'
    task :fetch do
      FileUtils.mkdir_p('downloads')
      role_set = Set.new([:web, :api])
      on roles(*role_set.to_a) do |host|
        role = (host.roles & role_set).to_a.join('-')
        download!(File.join(shared_path, 'log'), "downloads/#{role}-#{host.hostname}", recursive: true)
      end
    end

    desc 'Fetches the current logfiles from the cluster in question'
    task :fetch_current do
      FileUtils.mkdir_p('downloads')
      role_set = Set.new([:web, :api])
      on roles(*role_set.to_a) do |host|
        role = (host.roles & role_set).to_a.join('-')
        capture("cd #{shared_path} && ls -1 log/*.log log/**/*.log").split.each do |log|
          dir = File.dirname(log)
          download_dir = File.join('downloads' , "#{role}-#{host.hostname}", dir)
          FileUtils.mkdir_p(download_dir)
          download!(File.join(shared_path, log), download_dir, recursive: true)
        end
      end
    end
  end
  namespace :maintenance do
    desc 'Enables maintenance mode.'
    task :on do
      on release_roles(fetch(:assets_roles)) do
        within shared_path do
          execute :touch, 'MAINTENANCE'
        end
      end
    end
    desc 'Disables maintenance mode.'
    task :off do
      on release_roles(fetch(:assets_roles)) do
        within shared_path do
          execute :rm, 'MAINTENANCE'
        end
      end
    end
  end
end
