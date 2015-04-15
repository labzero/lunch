source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.0'
gem 'ruby-oci8'

# IF THE DB IS ACTING STRANGE, CHECK THIS BRANCH.
gem 'activerecord-oracle_enhanced-adapter', git: 'https://github.com/rsim/oracle-enhanced.git', branch: 'rails42' # they do not gaurantee backwards compatibility on non-patch changes
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'momentjs-rails'
gem 'bootstrap-daterangepicker-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc',          group: :doc
gem 'rest-client'
gem 'devise_ldap_authenticatable'

# Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
# gem 'spring',        group: :development

# Fix for 'No source of timezone data could be found.'
gem 'tzinfo-data'

gem 'haml-rails'

gem 'dotenv-rails'

# for parsing emails into CorporateCommunication objects
gem 'mail'
gem 'css_parser'

# Below are gems needed for the asset pipeline
gem 'sass-rails'
gem 'autoprefixer-rails' # automatically adds vendor prefixes to all applicable css
gem 'rails-sass-images' # allows us to measure native image dimensions in our scss
gem 'source-sans-pro-rails'
gem 'highcharts-rails'
gem 'jquery-placeholder-rails'
gem 'jquery-datatables-rails'

# for MAPI
gem 'sinatra', require: false
gem 'sinatra-activerecord', require: false
gem 'swagger-blocks', require: false
gem 'savon', require: false
gem 'nokogiri', require: false
gem 'rack-token_auth', require: false
gem 'logging', require: false

# for background tasks
gem 'resque'
gem 'wicked_pdf'
gem 'axlsx_rails', '>= 0.3.0'
gem 'resque-pool'

# for AWS assets
gem "paperclip", "~> 4.2"
gem 'fog-aws'

group :development, :test do
  gem 'rspec-rails'
  gem 'cucumber', '>= 2.0.0.rc1'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'foreman'
  gem 'rerun'
  gem 'brakeman'
  gem 'faker' #Faker library that generates fake data.
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
end

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use unicorn as the app server
# gem 'unicorn'

group :development do
  gem 'capistrano', '~> 3.2.0'
  gem 'capistrano-rvm'
  gem 'capistrano-rails'
  gem 'byebug' # debugger gem doesn't work with ruby 2.1.2
end


# Use debugger
# gem 'debugger', group: [:development, :test]

