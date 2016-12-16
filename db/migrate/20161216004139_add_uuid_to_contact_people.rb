class AddUuidToContactPeople < ActiveRecord::Migration
  def change
    add_column :contact_people, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :contact_people, :uuid, unique: true
  end
end
