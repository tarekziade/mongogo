# frozen_string_literal: true
# Pull gem index from rubygems
source 'https://rubygems.org'

# Pin the version of bundle we support
gem 'bundler', File.read(File.join(__dir__, '.bundler-version')).strip

# Dependencies for connectors
gem 'activesupport'
gem 'bson'
gem 'mime-types'
gem 'tzinfo-data'
gem 'concurrent-ruby'

group :test do
  gem 'rspec-collection_matchers'
  gem 'rspec-core'
  gem 'rspec_junit_formatter'
  gem 'rubocop', '1.18.4'
  gem 'rubocop-performance'
  gem 'rspec-mocks'
  gem 'webmock'
  gem 'rack-test'
  gem 'ruby-debug-ide'
  gem 'pry-remote'
  gem 'pry-nav'
  gem 'debase'
  gem 'timecop'
  gem 'simplecov', require: false
  gem 'simplecov-material'
end

# Dependencies for the HTTP service
gem 'sinatra'
gem 'sinatra-contrib'
gem 'rack'
gem 'forwardable'
gem 'faraday'
gem 'httpclient'
gem 'attr_extras'
gem 'hashie'
gem 'puma'

# Dependencies for oauth
gem 'signet'

# Dependencies for mongodb
gem 'mongo'

gem 'elasticsearch', '= 8.2.0'
gem 'faker'

