# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchAccountKeyWorker, type: :worker do # rubocop:disable Metrics/BlockLength
  subject(:worker) { described_class.new }
  let(:user) { create(:user, :without_account_key) }
  let(:account_key_service_double) { instance_double(AccountKeyService) }

  describe '#perform' do # rubocop:disable Metrics/BlockLength
    before do
      allow(AccountKeyService).to receive(:new).with(user.id).and_return(account_key_service_double)
    end

    context 'when user has no account_key' do
      before do
        allow(account_key_service_double).to receive(:fetch_account_key).and_return('account_key')
      end

      it 'fetches account_key' do
        expect { subject.perform(user.id) }.to change { user.reload.account_key }.from(nil).to('account_key')
      end
    end

    context 'when user does not exist' do
      let(:user_id) { -1 }

      it 'does not fetch account_key' do
        expect(account_key_service_double).not_to receive(:fetch_account_key)
        subject.perform(user_id)
      end

      it 'does not raise an error so the job is not retried' do
        expect { subject.perform(user_id) }.not_to raise_error
      end
    end

    context 'when user has an account_key' do
      let(:user) { create(:user, account_key: 'existing_key') }

      it 'does not fetch account_key' do
        expect(account_key_service_double).not_to receive(:fetch_account_key)
        subject.perform(user.id)
      end

      it 'does not update account_key' do
        expect { subject.perform(user.id) }.not_to(change { user.reload.account_key })
      end

      it 'does not raise an error so the job is not retried' do
        expect { subject.perform(user.id) }.not_to raise_error
      end
    end

    context 'when AccountKeyService fails' do
      before do
        allow(account_key_service_double).to receive(:fetch_account_key)
          .and_raise(FetchAccountKeyWorker::AccountKeyServiceError)
      end

      it 'raises an error to retry the job' do
        expect { subject.perform(user.id) }.to raise_error(FetchAccountKeyWorker::AccountKeyServiceError)
      end
    end

    context 'when unexpected error occurs' do
      before do
        allow(account_key_service_double).to receive(:fetch_account_key).and_raise(StandardError)
      end

      it 'raises an error to retry the job' do
        expect { subject.perform(user.id) }.to raise_error(StandardError)
      end
    end

    context 'when retries are exhausted' do
      let(:expected_message) do
        "Failed all (#{FetchAccountKeyWorker::MAX_RETRIES}) retry attempts with args: [#{user.id}]"
      end

      it 'logs a message' do
        expect(Rails.logger).to receive(:error).with(expected_message)

        subject.sidekiq_retries_exhausted_block.call({ 'args' => [user.id] }, StandardError.new)
      end
    end
  end
end
