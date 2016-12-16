class AddUuidToCompanyPartnerships < ActiveRecord::Migration
  def change
    add_column :company_partnerships, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :company_partnerships, :uuid, unique: true
  end
end
