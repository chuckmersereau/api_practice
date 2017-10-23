class AddGlobalRegistryColumns < ActiveRecord::Migration
  def change
    add_column :people, :global_registry_id, :uuid, null: true, default: nil
    add_column :people, :global_registry_mdm_id, :uuid, null: true, default: nil
    add_column :email_addresses, :global_registry_id, :uuid, null: true, default: nil
    add_column :phone_numbers, :global_registry_id, :uuid, null: true, default: nil
  end
end
