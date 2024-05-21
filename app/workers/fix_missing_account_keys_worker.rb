# frozen_string_literal: true

class FixMissingAccountKeysWorker
  include ApplicationLogger
  include Sidekiq::Worker

  MAX_USERS_PER_RUN = 100

  def perform
    log_message(:info, 'Started!')

    processed_users = 0
    users_to_fix.find_each do |user|
      log_message(:info, "Fetching account key for user id: #{user.id}")
      FetchAccountKeyWorker.perform_async(user.id)
      processed_users += 1
    end

    log_message(:info, "Finished! Processed #{processed_users} user(s).")
  end

  private

  def users_to_fix
    User.without_account_key.limit(MAX_USERS_PER_RUN).select(:id)
  end
end
