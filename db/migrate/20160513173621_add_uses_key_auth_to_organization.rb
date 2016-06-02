class AddUsesKeyAuthToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :uses_key_auth, :boolean, default: false
  end
end
