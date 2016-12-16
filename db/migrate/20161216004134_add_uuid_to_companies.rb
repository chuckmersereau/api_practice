class AddUuidToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :companies, :uuid, unique: true
  end
end
