# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  # Secure Sidekiq web dashboard in production. Otherwise, keep it open
  if Rails.env.production?
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch('SIDEKIQ_USERNAME', nil)) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch('SIDEKIQ_PASSWORD', nil))
    end
  end

  namespace :api do
    # It would be good to add versioning here as well.
    # I'll keep it without versionong because it was not requested in the task.
    resources :users, only: %i[index create]
  end
end
