class AddUuidToMasterCompanies < ActiveRecord::Migration
  def change
    add_column :master_companies, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :master_companies, :uuid, unique: true
  end
end
