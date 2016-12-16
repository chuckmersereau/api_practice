class AddUuidToPeople < ActiveRecord::Migration
  def change
    add_column :people, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :people, :uuid, unique: true
  end
end
