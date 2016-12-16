class AddUuidToPersonWebsites < ActiveRecord::Migration
  def change
    add_column :person_websites, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :person_websites, :uuid, unique: true
  end
end
