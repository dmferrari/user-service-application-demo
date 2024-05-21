# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::UsersController, type: :controller do # rubocop:disable Metrics/BlockLength
  shared_examples :successful_response do
    it 'returns http success' do
      expect(response).to have_http_status(:success)
    end
  end

  shared_examples :unprocessable_entity_response do
    it 'returns http unprocessable entity' do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  shared_examples :created_response do
    it 'returns http created' do
      expect(response).to have_http_status(:created)
    end
  end

  describe 'GET #index' do # rubocop:disable Metrics/BlockLength
    let!(:users) do
      [
        FactoryBot.create(:user, :without_account_key, :without_key, created_at: 1.hour.ago),
        FactoryBot.create(:user, :without_account_key, :without_key, created_at: 4.hours.ago),
        FactoryBot.create(:user, :without_account_key, :without_key, created_at: 12.months.ago),
        FactoryBot.create(:user, :without_account_key, :without_key, created_at: 2.hours.ago),
        FactoryBot.create(:user, :without_account_key, :without_key, created_at: 5.days.ago),
        FactoryBot.create(:user, :without_account_key, :without_key, created_at: 3.hours.ago)
      ]
    end

    context 'without query params' do
      let(:serialized_users) { ActiveModelSerializers::SerializableResource.new(User.recent).as_json }

      before { get :index }

      it_behaves_like :successful_response

      it 'responds with the expected users' do
        expect(response.parsed_body).to eq(serialized_users.as_json)
      end
    end

    context 'with query params' do # rubocop:disable Metrics/BlockLength
      let(:expected_users) do
        User.scoped_users(email: query_params[:email],
                          full_name: query_params[:full_name],
                          metadata: query_params[:metadata])
      end
      let(:serialized_users) { ActiveModelSerializers::SerializableResource.new(expected_users).as_json }

      context 'with empty query params' do
        let(:query_params) { {} }

        before { get :index, params: query_params }

        it_behaves_like :successful_response

        it 'responds with the expected users' do
          expect(response.parsed_body).to eq(serialized_users.as_json)
        end
      end

      context 'with all params set' do
        let(:query_params) do
          {
            email: users.first.email,
            full_name: users.first.full_name,
            metadata: users.first.metadata
          }
        end

        before { get :index, params: query_params }

        it_behaves_like :successful_response

        it 'responds with the expected users' do
          expect(response.parsed_body).to eq(serialized_users.as_json)
        end
      end

      context 'with just email set' do
        let(:query_params) { { email: users.last.email } }

        before { get :index, params: query_params }

        it_behaves_like :successful_response

        it 'responds with the expected users' do
          expect(response.parsed_body).to eq(serialized_users.as_json)
        end
      end

      context 'with just full_name set' do
        let(:query_params) { { full_name: users.last.full_name } }

        before { get :index, params: query_params }

        it_behaves_like :successful_response

        it 'responds with the expected users' do
          expect(response.parsed_body).to eq(serialized_users.as_json)
        end
      end

      context 'with just metadata set' do
        let(:query_params) { { metadata: 'Male' } }

        before { get :index, params: query_params }

        it_behaves_like :successful_response

        it 'responds with the expected users' do
          expect(response.parsed_body).to eq(serialized_users.as_json)
        end
      end
    end

    context 'with unexpected query params' do
      let(:query_params) { { unexpected_param: 'unexpected' } }

      before { get :index, params: query_params }

      it_behaves_like :unprocessable_entity_response

      it 'returns the expected error' do
        expect(response.parsed_body).to eq('errors' => ['Unexpected parameter(s): unexpected_param'])
      end
    end
  end

  describe 'POST #create' do # rubocop:disable Metrics/BlockLength
    context 'with valid params' do
      let(:serialized_users) { ActiveModelSerializers::SerializableResource.new(User.last).as_json }
      let(:user_params) { FactoryBot.attributes_for(:user, :without_account_key, :without_key) }

      before { post :create, params: { user: user_params } }

      it_behaves_like :created_response

      it 'responds with the expected users' do
        expect(response.parsed_body).to eq(serialized_users.as_json)
      end

      it 'creates a new user' do
        expect(User.count).to eq(1)
      end
    end

    context 'job enqueuing' do
      let!(:user_params) { FactoryBot.attributes_for(:user, :without_account_key, :without_key) }

      it 'enqueues a new FetchAccountKeyWorker job' do
        expect do
          post :create, params: { user: user_params }
        end.to change(FetchAccountKeyWorker.jobs, :size).by(1)

        expect(FetchAccountKeyWorker.jobs.last['args']).to eq([User.last.id])
      end
    end

    context 'with missing required params' do
      let(:user_params) { FactoryBot.attributes_for(:user, :without_account_key, :without_key).except(:email) }

      before { post :create, params: { user: user_params } }

      it_behaves_like :unprocessable_entity_response

      it 'does not create a new user' do
        expect(User.count).to eq(0)
      end

      it 'returns the expected error message' do
        expect(response.parsed_body).to eq('errors' => ["Email can't be blank"])
      end
    end
  end
end
