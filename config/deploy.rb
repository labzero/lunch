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
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

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

  before :compile_assets, :clear_tmp
  before :publishing, :missing_dirs
  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
