# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do # rubocop:disable Metrics/BlockLength
  subject(:user) { described_class.new(attributes_for(:user, :without_account_key, :without_key)) }

  describe 'validations' do # rubocop:disable Metrics/BlockLength
    shared_examples 'a saved record' do
      it 'saves successfully' do
        expect { subject.save! }.to change(User, :count).by(1)
      end
    end

    shared_examples 'an invalid record' do |message|
      it "does not save due to #{message}" do
        expect { subject.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with account_key' do
      context 'when missing' do
        before { subject.account_key = nil }
        include_examples 'a saved record'
      end

      context 'when too long' do
        before { subject.account_key = 'a' * (User::MAX_ACCOUNT_KEY_LENGTH + 1) }
        include_examples 'an invalid record', 'excessive account_key length'
      end
    end

    context 'with email' do
      context 'when missing' do
        before { subject.email = nil }
        include_examples 'an invalid record', 'missing email'
      end

      context 'when not unique' do
        before { create(:user, email: subject.email) }
        include_examples 'an invalid record', 'non-unique email'
      end

      context 'when too long' do
        before { subject.email = 'a' * (User::MAX_EMAIL_LENGTH + 1) }
        include_examples 'an invalid record', 'excessive email length'
      end

      context 'when email is not downcased' do
        before { subject.email = subject.email.upcase }

        it 'downcases the email' do
          subject.save!
          expect(subject.reload.email).to eq(subject.email.downcase)
        end
      end
    end

    context 'with full_name' do
      context 'when missing' do
        before { subject.full_name = nil }
        include_examples 'a saved record'
      end

      context 'when too long' do
        before { subject.full_name = 'a' * (User::MAX_FULL_NAME_LENGTH + 1) }
        include_examples 'an invalid record', 'excessive full_name length'
      end
    end

    context 'with key' do
      context 'when not unique' do
        before do
          subject.key = 'key'
          create(:user, key: user.key)
        end
        include_examples 'an invalid record', 'non-unique key'
      end

      context 'when too long' do
        before { subject.key = 'a' * (User::MAX_KEY_LENGTH + 1) }
        include_examples 'an invalid record', 'excessive key length'
      end
    end

    context 'with metadata' do
      context 'when missing' do
        before { subject.metadata = nil }
        include_examples 'a saved record'
      end

      context 'when too long' do
        before { subject.metadata = 'a' * (User::MAX_METADATA_LENGTH + 1) }
        include_examples 'an invalid record', 'excessive metadata length'
      end
    end

    context 'with phone_number' do
      context 'when phone_number is missing' do
        before { subject.phone_number = nil }
        include_examples 'an invalid record', 'missing phone number'
      end

      context 'when not unique' do
        before { create(:user, phone_number: subject.phone_number) }
        include_examples 'an invalid record', 'non-unique phone_number'
      end

      context 'when too long' do
        before { subject.phone_number = '5' * (User::MAX_PHONE_NUMBER_LENGTH + 1) }
        include_examples 'an invalid record', 'excessive phone_number length'
      end
    end

    context 'with account_key' do
      context 'when user is created' do
        include_examples 'a saved record'

        it 'does not set the account_key' do
          subject.save!
          expect(subject.account_key).to be_nil
        end
      end

      context 'when account_key is updated' do
        let!(:account_key) { 'account_key' }
        let!(:user) { create(:user, :without_account_key) }

        it 'sends the account_key to the ClientApplication' do
          expect(SendAccountKeyToClientApplicationWorker).to receive(:perform_async).with(user.email, account_key)
          user.update!(account_key:)
        end
      end
    end
  end

  describe 'scopes' do # rubocop:disable Metrics/BlockLength
    describe '.recent' do
      let!(:user_recent) { create(:user, created_at: 1.minute.ago) }
      let!(:user_older) { create(:user, created_at: 10.minutes.ago) }

      it 'returns users in descending order of creation' do
        expect(User.recent).to eq([user_recent, user_older])
      end
    end

    describe '.with_email' do
      let!(:user_recent) { create(:user, created_at: 1.minute.ago) }
      let!(:user_with_email) { create(:user, email: 'test@example.com') }
      let!(:user_with_full_name) { create(:user, full_name: 'John Doe') }

      it 'returns users with the specified email' do
        expect(User.with_email('test@example.com')).to include(user_with_email)
        expect(User.with_email('test@example.com')).not_to include(user_recent, user_with_full_name)
      end
    end

    describe '.with_full_name' do
      let!(:user_recent) { create(:user, created_at: 1.minute.ago) }
      let!(:user_with_email) { create(:user, email: 'test@example.com') }
      let!(:user_with_full_name) { create(:user, full_name: 'John Doe') }

      it 'returns users with the specified full name' do
        expect(User.with_full_name('John Doe')).to include(user_with_full_name)
        expect(User.with_full_name('John Doe')).not_to include(user_recent, user_with_email)
      end
    end

    describe '.with_metadata' do
      let!(:user_recent) { create(:user, created_at: 1.minute.ago) }
      let!(:user_with_email) { create(:user, email: 'test@example.com') }
      let!(:user_with_full_name) { create(:user, full_name: 'John Doe') }
      let!(:user_with_metadata) { create(:user, metadata: 'Some metadata content') }

      it 'returns users with matching metadata' do
        expect(User.with_metadata('metadata')).to include(user_with_metadata)
        expect(User.with_metadata('metadata')).not_to include(user_recent, user_with_email, user_with_full_name)
      end
    end

    describe '.without_account_key' do
      let!(:user_without_account_key) { create(:user, account_key: nil) }
      let!(:user_with_account_key) { create(:user, account_key: 'abc123') }

      it 'returns users without an account key' do
        expect(User.without_account_key).to include(user_without_account_key)
        expect(User.without_account_key).not_to include(user_with_account_key)
      end
    end
  end

  describe 'callbacks' do # rubocop:disable Metrics/BlockLength
    describe 'before_validation callbacks' do
      context 'when email is provided in uppercase' do
        let(:user) { build(:user, email: 'TEST@EXAMPLE.COM') }

        it 'converts the email to lowercase' do
          user.valid?
          expect(user.email).to eq('test@example.com')
        end
      end

      context 'when key is blank' do
        let(:user) { build(:user, key: '') }

        it 'assigns a key' do
          user.valid?
          expect(user.key).not_to be_blank
        end
      end
    end

    describe 'after_update callbacks' do
      context 'when the account_key is updated' do
        let(:user) { create(:user, account_key: nil) }
        let(:new_account_key) { 'account-key' }

        it 'runs the check_account_key_assignation' do
          expect(SendAccountKeyToClientApplicationWorker).to receive(:perform_async).with(user.email, new_account_key)
          user.update!(account_key: new_account_key)
        end
      end
    end
  end

  describe '.scoped_users' do # rubocop:disable Metrics/BlockLength
    let(:email) { 'specific-email@example.com' }
    let(:full_name) { 'Specific Name' }
    let(:metadata) { 'specific metadata' }
    let(:user_recent) { create(:user, created_at: 1.day.ago) }
    let(:user_older) { create(:user, created_at: 2.days.ago) }
    let(:user_with_email) { create(:user, email:, created_at: 3.days.ago) }
    let(:user_with_full_name) { create(:user, full_name:, created_at: 4.days.ago) }
    let(:user_with_metadata) { create(:user, metadata:, created_at: 5.days.ago) }

    context 'when filtering by email' do
      it 'returns users with the specified email' do
        expect(User.scoped_users(email:)).to match_array([user_with_email])
      end
    end

    context 'when filtering by full name' do
      it 'returns users with the specified full name' do
        expect(User.scoped_users(full_name:)).to match_array([user_with_full_name])
      end
    end

    context 'when filtering by metadata' do
      it 'returns users with matching metadata' do
        expect(User.scoped_users(metadata:)).to match_array([user_with_metadata])
      end
    end

    context 'when applying multiple filters' do
      it 'returns users that match all filters' do
        users = User.scoped_users(email: user_recent.email,
                                  full_name: user_recent.full_name,
                                  metadata: user_recent.metadata)

        expect(users).to match_array([user_recent])
      end
    end

    context 'when applying no filters' do
      it 'returns all users in descending order of creation' do
        users = User.scoped_users
        expect(users).to eq([user_recent, user_older, user_with_email, user_with_full_name, user_with_metadata])
      end
    end
  end
end
