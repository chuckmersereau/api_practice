class AddUuidToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :activities, :uuid, unique: true
  end
end
