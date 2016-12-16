class AddUuidToHelpRequests < ActiveRecord::Migration
  def change
    add_column :help_requests, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :help_requests, :uuid, unique: true
  end
end
