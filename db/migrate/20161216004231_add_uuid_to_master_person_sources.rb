class AddUuidToMasterPersonSources < ActiveRecord::Migration
  def change
    add_column :master_person_sources, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :master_person_sources, :uuid, unique: true
  end
end
