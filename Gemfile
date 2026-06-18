# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Specify your gem's dependencies in minting-rails.gemspec.
gemspec

gem 'minting'

gem 'puma'
gem 'sqlite3', '>= 2.0'

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"
#
group :development do
  gem 'rubocop'
  gem 'rubocop-minitest'
  gem 'rubocop-packaging'
  gem 'rubocop-performance'
  gem 'rubocop-rails'
  gem 'rubocop-rake'
  gem 'rubocop-thread_safety'
  gem 'solargraph'
end

group :benchmark do
  gem 'benchmark'
  gem 'money-rails'
end
