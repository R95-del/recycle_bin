# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in recycle_bin.gemspec
gemspec

gem 'rake', '~> 13.0'
gem 'rspec', '~> 3.0'

# Development dependencies
group :development, :test do
  gem 'factory_bot_rails', '~> 6.2'
  gem 'rspec-rails', '>= 6.0'
  gem 'sqlite3', '~> 2.0'
end

group :development do
  gem 'rubocop', '~> 1.50', require: false
  gem 'rubocop-rails', '~> 2.19', require: false
  gem 'rubocop-rspec', '~> 2.20', require: false
end
