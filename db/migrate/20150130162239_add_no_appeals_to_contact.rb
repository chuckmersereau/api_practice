class AddNoAppealsToContact < ActiveRecord::Migration
  def change
    add_column :contacts, :no_appeals, :boolean
  end
end
