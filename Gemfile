source 'https://rubygems.org'

gem 'rails', '4.2.6'
gem 'ruby-oci8'

# IF THE DB IS ACTING STRANGE, CHECK THIS BRANCH.
# before upgrading, consult rails version compaitibility: https://github.com/rsim/oracle-enhanced#rails-42
gem 'activerecord-oracle_enhanced-adapter', '~> 1.6.0' # they do not gaurantee backwards compatibility on non-patch changes
gem 'uglifier'
gem 'jquery-rails'
gem 'momentjs-rails'
gem 'bootstrap-daterangepicker-rails', '0.1.1'

# for speeding up links (https://github.com/rails/turbolinks)
gem 'turbolinks', '~> 2.5.3'

# for json APIs (https://github.com/rails/jbuilder)
gem 'jbuilder'

# for docs (bundle exec rake doc:rails generates the API under doc/api)
gem 'sdoc', group: :doc
gem 'rest-client', '~> 1.8.0'
gem 'http'
gem 'securid'

# for authentication/authorization
gem 'devise', '~> 4.1.1'
gem 'devise_ldap_authenticatable', git: 'https://github.com/labzero/devise_ldap_authenticatable.git', branch: '0.9.21'
gem 'pundit'

# for 'No source of timezone data could be found' fix
gem 'tzinfo-data'

gem 'haml-rails', '~> 0.9.0'

gem 'dotenv-rails'
gem 'redis-rails'
gem 'aasm', '~> 4.10.1'
gem 'redis-objects'

# for feature flipping
gem 'flipper'
gem 'flipper-redis'
gem 'flipper-ui'

# for parsing emails into CorporateCommunication objects
gem 'mail'
gem 'css_parser'

# for the asset pipeline
gem 'sass-rails'
gem 'autoprefixer-rails' # automatically adds vendor prefixes to all applicable css
gem 'rails-sass-images' # allows us to measure native image dimensions in our scss
gem 'highcharts-rails'
gem 'jquery-placeholder-rails'
gem 'jquery-datatables-rails'
gem 'client_side_validations', git: 'https://github.com/DavyJonesLocker/client_side_validations.git', branch: '4-2-stable'
gem 'mini_magick' # for manipulating images during asset precompile

# for MAPI
gem 'sinatra', require: false
gem 'sinatra-activerecord', require: false
gem 'swagger-blocks', '~> 1.3.3', require: false
gem 'savon', require: false
gem 'rack-token_auth', require: false
gem 'logging', require: false

# for background tasks
gem 'resque'
gem 'wicked_pdf'
gem 'axlsx_rails', '~> 0.5.1'
gem 'resque-pool'
gem 'resque-scheduler'

# for uploading/processing xlsx
gem 'roo'
gem 'jquery-fileupload-rails'

# for AWS assets
gem 'paperclip'
gem 'fog-aws'

# for ActionMailer
gem 'nokogiri'
gem 'premailer-rails'

# for profiling
gem 'ruby-prof', require: false

# for validating CUSIPs
gem 'security_identifiers', '~> 0.1.1'

# for Prismic CMS integration
gem 'prismic.io', require: 'prismic'

# for communicating with the enterprise message bus
gem 'net-sftp'
gem 'stomp'

group :production, :development do
  gem 'newrelic_rpm'
end

group :development, :test do
  gem 'rspec-rails', '~> 3.4.2'
  gem 'cucumber'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'foreman'
  gem 'rerun'
  gem 'brakeman'
  gem 'faker'
  gem 'simplecov-rcov', require: false
  gem 'parallel_tests'
end

group :test do
  gem 'vcr'
  gem 'webmock'
  gem 'timecop'
  gem 'shoulda-matchers', require: false
  gem 'factory_girl_rails'
  gem 'net-ping'
  gem 'database_cleaner'
  gem 'shoulda-callback-matchers'
  gem 'sauce_whisk', '~> 0.0.21'
end

group :development do
  gem 'capistrano'
  gem 'capistrano-rvm'
  gem 'capistrano-rails'
  gem 'growl'
  gem 'byebug' # debugger gem doesn't work with ruby 2.1.2
  gem 'letter_opener'
end

# gem 'debugger', group: [:development, :test]