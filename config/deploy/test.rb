set :rails_env, 'production'
set :branch, ENV['CAP_BRANCH'] || "develop"

nodes = JSON.parse(ENV['MEMBER_TEST_NODES'])

nodes.each do |ip, details|
  server ip, user: 'ubuntu', roles: details['roles'], primary: !!details['primary']
end

set :ssh_options, {
    keys: %w(~/.ssh/fhlbsf-test.pem),
    forward_agent: false,
    auth_methods: %w(publickey)
}