class AddUuidToPhoneNumbers < ActiveRecord::Migration
  def change
    add_column :phone_numbers, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :phone_numbers, :uuid, unique: true
  end
end
