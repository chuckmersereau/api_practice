class AddUuidToAppeals < ActiveRecord::Migration
  def change
    add_column :appeals, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :appeals, :uuid, unique: true
  end
end
