# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountKeyService, type: :service do # rubocop:disable Metrics/BlockLength
  subject(:service) { described_class.new(user.id) }
  let(:user) { create(:user, :without_account_key) }

  describe '#fetch_account_key' do # rubocop:disable Metrics/BlockLength
    before do
      allow(service).to receive(:fake_account_key_for).and_return('fake_account_key-123')
    end

    context 'when user has no account_key' do
      it 'successfully fetches an account_key' do
        expect { service.fetch_account_key }.not_to raise_error
        expect(service).to have_received(:fake_account_key_for)
      end

      it 'raises an AccountKeyServiceError when retrieval fails' do
        allow(service).to receive(:fake_account_key_for).and_raise(AccountKeyService::AccountKeyServiceError)

        expect { service.fetch_account_key }.to raise_error(AccountKeyService::AccountKeyServiceError)
        expect(service).to have_received(:fake_account_key_for)
      end
    end

    context 'when user has an account_key' do
      let(:user) { create(:user, account_key: 'existing_key') }

      it 'does not attempt to fetch an account_key' do
        expect(service).not_to receive(:fake_account_key_for)
      end
    end

    context 'when user does not exist' do
      let(:nonexistent_user_id) { -1 }
      subject(:service_with_nonexistent_user) { described_class.new(nonexistent_user_id) }

      it 'logs a message and returns nil' do
        expect(service_with_nonexistent_user.fetch_account_key).to be_nil
      end

      it 'does not attempt to fetch an account_key' do
        expect(service).not_to receive(:fake_account_key_for)
      end
    end
  end
end
