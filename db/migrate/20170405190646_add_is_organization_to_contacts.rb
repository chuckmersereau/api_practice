class AddIsOrganizationToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :is_organization, :boolean, default: false
  end
end
