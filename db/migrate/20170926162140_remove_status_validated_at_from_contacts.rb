class RemoveStatusValidatedAtFromContacts < ActiveRecord::Migration
  def change
    remove_column :contacts, :status_validated_at, :datetime
  end
end
