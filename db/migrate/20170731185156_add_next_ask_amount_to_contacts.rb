class AddNextAskAmountToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :next_ask_amount, :decimal, precision: 19, scale: 2
  end
end
