# frozen_string_literal: true

module ApplicationLogger
  def log_message(level, message)
    message = message.join(',') if message.is_a?(Array)
    Rails.logger.send(level, "*** [#{self.class.name}]: #{message}")
  end
end
