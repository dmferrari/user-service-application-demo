# frozen_string_literal: true

class ClientService
  extend ApplicationLogger

  def self.send_account_key(email, _account_key)
    log_message(:info, "Account key sent to ClientApplication for user #{email}")

    # TODO: POST to client sending a webhook with the user's email and
    # account_key in the body using Faraday
  end
end
