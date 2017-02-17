class AddStatusValidationToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :status_valid, :boolean
    add_column :contacts, :status_validated_at, :datetime
    add_index :contacts, :status_validated_at
    add_column :contacts, :suggested_changes, :text
  end
end
