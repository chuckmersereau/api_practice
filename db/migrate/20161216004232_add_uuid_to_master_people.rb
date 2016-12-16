class AddUuidToMasterPeople < ActiveRecord::Migration
  def change
    add_column :master_people, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :master_people, :uuid, unique: true
  end
end
