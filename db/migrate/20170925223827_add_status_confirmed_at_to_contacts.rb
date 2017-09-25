class AddStatusConfirmedAtToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :status_confirmed_at, :datetime
  end
end
