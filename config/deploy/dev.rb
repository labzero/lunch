set :rails_env, 'production'
set :branch, ENV['CAP_BRANCH'] || "develop"

nodes = JSON.parse(ENV['MEMBER_DEV_NODES'] || '{}')

nodes.each do |ip, details|
  server ip, user: 'ubuntu', roles: details['roles'], primary: !!details['primary']
end

set :ssh_options, {
    keys: [ENV['CAP_SSH_KEY'] || '~/.ssh/fhlbsf-dev.pem'],
    forward_agent: false,
    auth_methods: %w(publickey)
}