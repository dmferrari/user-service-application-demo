# frozen_string_literal: true

class FetchAccountKeyWorker
  include ApplicationLogger
  include Sidekiq::Worker

  class AccountKeyServiceError < StandardError; end

  # Don't go too far, it's exponential
  MAX_RETRIES = 3
  sidekiq_options retry: MAX_RETRIES

  sidekiq_retries_exhausted do |msg, _ex|
    Rails.logger.error("Failed all (#{MAX_RETRIES}) retry attempts with args: #{msg['args']}")

    # TODO: Send notification to Sentry
  end

  def perform(user_id, account_key_service: AccountKeyService) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    log_message(:info, "Fetch account_key for user id: #{user_id} started!")

    user = User.find_by(id: user_id)

    if user.nil?
      log_message(:info, "User id: #{user_id} not found. Skipping!")
      return
    end

    if user.account_key.present?
      log_message(:info, "User id: #{user_id} has already an account_key. Skipping!")
      return
    end

    account_key = account_key_service.new(user_id).fetch_account_key

    if account_key.blank?
      message = "User id: #{user_id} - AccountKeyService did not return an account key. Will retry"
      log_message(:warn, message)
      raise AccountKeyServiceError, message
    end

    user.update!(account_key:)
    log_message(:info, "Fetch account_key for user id: #{user_id} finished!")
  rescue AccountKeyServiceError => e
    log_message(:error, "User id: #{user_id} - AccountKeyService error: #{e.message}")
    raise e
  rescue StandardError => e
    log_message(:error, "User id: #{user_id} - Unexpected error: #{e.message}")
    raise e
  end
end
