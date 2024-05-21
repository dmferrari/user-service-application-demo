# frozen_string_literal: true

class UserSerializer < ActiveModel::Serializer
  attributes :email, :phone_number, :full_name, :key, :account_key, :metadata
end
