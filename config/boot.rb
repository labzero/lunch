# Set up gems listed in the Gemfile.
ENV['NLS_LANG'] ||= 'AMERICAN_AMERICA.UTF8'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
ENV['DEPLOY_REVISION'] ||= (
  revision = `cat ./REVISION 2>/dev/null`.strip
  revision == '' ? nil : revision
)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
