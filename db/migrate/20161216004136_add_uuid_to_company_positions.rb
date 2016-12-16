class AddUuidToCompanyPositions < ActiveRecord::Migration
  def change
    add_column :company_positions, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :company_positions, :uuid, unique: true
  end
end
