# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  MAX_ACCOUNT_KEY_LENGTH = 100
  MAX_EMAIL_LENGTH = 200
  MAX_FULL_NAME_LENGTH = 200
  MAX_KEY_LENGTH = 200
  MAX_METADATA_LENGTH = 2000
  MAX_PHONE_NUMBER_LENGTH = 20

  validates :account_key, length: { maximum: MAX_ACCOUNT_KEY_LENGTH }
  validates :email, presence: true, uniqueness: true, length: { maximum: MAX_EMAIL_LENGTH }
  validates :full_name, length: { maximum: MAX_FULL_NAME_LENGTH }
  validates :key, presence: true, uniqueness: true, length: { maximum: MAX_KEY_LENGTH }
  validates :metadata, length: { maximum: MAX_METADATA_LENGTH }
  validates :phone_number, presence: true, uniqueness: true, length: { maximum: MAX_PHONE_NUMBER_LENGTH }

  scope :recent, -> { order(created_at: :desc) }
  scope :with_email, ->(email) { where(email:) if email.present? }
  scope :with_full_name, ->(full_name) { where(full_name:) if full_name.present? }
  scope :with_metadata, ->(metadata) { where('metadata ILIKE ?', "%#{metadata}%") if metadata.present? }
  scope :without_account_key, -> { where(account_key: nil) }

  before_validation { email&.downcase! }
  before_validation :assign_key, if: -> { key.blank? }, on: :create
  after_update :check_account_key_assignation

  def self.scoped_users(email: nil, full_name: nil, metadata: nil)
    User.with_email(email).with_full_name(full_name).with_metadata(metadata).recent
  end

  private

  def assign_key
    # SecureRandom.hex generates keys twice as long as the parameter sent, so
    # to keep it within the MAX_KEY_LENGTH, we divide it by 2.
    actual_key_length = MAX_KEY_LENGTH / 2
    self.key = SecureRandom.hex(actual_key_length)
  end

  def check_account_key_assignation
    return unless saved_change_to_attribute?(:account_key)

    log_message(:info, "Account key for user id: #{id} updated: xxxxxx#{account_key.last(4)}")
    SendAccountKeyToClientApplicationWorker.perform_async(email, account_key)
  end
end
