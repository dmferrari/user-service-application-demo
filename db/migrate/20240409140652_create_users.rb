# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[7.1]
  def change # rubocop:disable Metrics/MethodLength
    create_table :users do |t|
      t.string :email, null: false, limit: 200
      t.string :phone_number, null: false, limit: 20
      t.string :full_name, limit: 200
      t.string :password_digest
      t.string :key, null: false, limit: 200
      t.string :account_key, limit: 100
      t.text :metadata

      t.timestamps
    end
    add_index :users, :account_key, unique: true
    add_index :users, :email, unique: true
    add_index :users, :key, unique: true
    add_index :users, :phone_number, unique: true
  end
end
