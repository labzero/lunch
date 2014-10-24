set :rails_env, 'production'
set :branch, fetch(:branch, "master")

server 'example.com', user: 'ubuntu', roles: %w{web app db}, primary: true

set :ssh_options, {
    keys: %w(~/.ssh/fhlb-prod.pem),
    forward_agent: false,
    auth_methods: %w(publickey)
}