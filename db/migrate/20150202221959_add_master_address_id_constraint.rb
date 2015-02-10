class AddMasterAddressIdConstraint < ActiveRecord::Migration
  def change
    Address.where(master_address_id: nil).find_each(batch_size: 500) do |address|
      address.find_or_create_master_address
      address.save!
    end

    change_column_null :addresses, :master_address_id, false
  end
end
