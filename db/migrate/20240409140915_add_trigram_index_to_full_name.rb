# frozen_string_literal: true

class AddTrigramIndexToFullName < ActiveRecord::Migration[7.1]
  def up
    add_index :users, :full_name, using: :gin, opclass: :gin_trgm_ops
  end

  def down
    remove_index :users, :full_name
  end
end
