class AddUuidToActivityComments < ActiveRecord::Migration
  def change
    add_column :activity_comments, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :activity_comments, :uuid, unique: true
  end
end
