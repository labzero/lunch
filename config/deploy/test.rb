set :rails_env, 'production'
set :branch, ENV['CAP_BRANCH'] || "develop"

server 'example.com', user: 'ubuntu', roles: %w{web app db}, primary: true

set :ssh_options, {
    keys: %w(~/.ssh/fhlb-test.pem),
    forward_agent: false,
    auth_methods: %w(publickey)
}