# frozen_string_literal: true

class SendAccountKeyToClientApplicationWorker
  include ApplicationLogger
  include Sidekiq::Worker

  def perform(email, account_key)
    log_message(:info, "Sending webhook with account_key for user: #{email}")
    ClientService.send_account_key(email, account_key)
  end
end
