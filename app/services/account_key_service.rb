# frozen_string_literal: true

class AccountKeyService
  include ApplicationLogger

  class AccountKeyServiceError < StandardError; end

  def initialize(user_id)
    @user_id = user_id
  end

  def fetch_account_key
    user = User.find_by(id: @user_id)

    if user.nil?
      log_message(:info, "User ID: #{@user_id} not found. Aborting")
      return
    end

    if user.account_key.present?
      log_message(:info, "User ID: #{user.id} already has an account key. Aborting")
      return
    end

    fake_account_key_for(user.email, user.key)
  end

  private

  def fake_account_key_for(_email, _key)
    # Simulating unreliability with random failures
    if rand(2).zero?
      log_message(:error, 'Simulating unreliability: Failed to retrieve account key.')
      raise AccountKeyServiceError, 'Service is currently unavailable due to simulated unreliability.'
    else
      "fake_account_key-#{SecureRandom.hex(20)}"
    end
  end
end
