class AddGiftAidToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :gift_aid_percentage, :decimal
  end
end
