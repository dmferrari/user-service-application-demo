# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.3.0'
gem 'rails', '~> 7.1.3', '>= 7.1.3.2'

gem 'active_model_serializers'
gem 'bcrypt'
gem 'bootsnap', require: false
gem 'bundler', '~> 2.5.7'
gem 'cancancan'
gem 'faraday'
gem 'pg'
gem 'puma'
gem 'redis'
gem 'sidekiq'
gem 'sidekiq-scheduler'

group :development, :test do
  gem 'byebug'
  gem 'dotenv-rails', '~> 3.1'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rubocop', require: false
  gem 'rubocop-rails'
end

group :development do
  gem 'bullet'
  gem 'rack-mini-profiler'
  gem 'rails-perftest'
  gem 'reek'
  gem 'ruby-lsp'
  gem 'ruby-prof'
  gem 'spring'
end

group :test do
  gem 'rspec-rails'
  gem 'rspec-sidekiq'
end
