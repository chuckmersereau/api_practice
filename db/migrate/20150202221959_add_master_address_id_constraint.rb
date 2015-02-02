class AddMasterAddressIdConstraint < ActiveRecord::Migration
  def change
    Address.where(master_address_id: nil).each do |address|
      address.find_or_create_master_address
    end

    change_column_null :addresses, :master_address_id, false
  end
end
