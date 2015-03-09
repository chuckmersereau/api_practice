class RemoveNeverAskFromContacts < ActiveRecord::Migration
  def change
    Contact.where(never_ask: true).update_all(no_appeals: true)
    remove_column :contacts, :never_ask
  end
end
