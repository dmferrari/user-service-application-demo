# frozen_string_literal: true

module Api
  class UsersController < ApplicationController
    class WrongParameters < StandardError; end

    def index
      validate_query_params!

      # Not something requested, but pagination is recommended to avoid getting
      # ton of users in the response.

      users = User.scoped_users(email: filter_params[:email],
                                full_name: filter_params[:full_name],
                                metadata: filter_params[:metadata])

      render json: users, status: :ok
    rescue UsersController::WrongParameters => e
      log_message(:error, e.message)
      render json: { errors: [e.message] }, status: :unprocessable_entity
    end

    def create
      user = User.new user_params

      if user.save
        FetchAccountKeyWorker.perform_async(user.id)
        log_message(:info, "User id: #{user.id} created")
        render json: user, status: :created
      else
        error_messages = user.errors.full_messages
        log_message(:error, error_messages)
        render json: { errors: error_messages }, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:email, :full_name, :metadata, :password, :phone_number)
    end

    def filter_params
      params.permit(:email, :full_name, :metadata)
    end

    def validate_query_params!
      permitted_keys = filter_params.keys + %w[controller action]
      extra_keys = params.keys - permitted_keys
      return unless extra_keys.any?

      raise WrongParameters, "Unexpected parameter(s): #{extra_keys.join(', ')}"
    end
  end
end
