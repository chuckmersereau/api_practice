class AddUuidToDesignationProfiles < ActiveRecord::Migration
  def change
    add_column :designation_profiles, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :designation_profiles, :uuid, unique: true
  end
end
