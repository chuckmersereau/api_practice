class AddNoGiftAidToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :no_gift_aid, :boolean
  end
end
