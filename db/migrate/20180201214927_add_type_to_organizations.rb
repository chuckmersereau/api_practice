class AddTypeToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :organization_type, :string, default: 'Non-Cru'
  end
end
