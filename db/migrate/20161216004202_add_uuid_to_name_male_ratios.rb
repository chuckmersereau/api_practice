class AddUuidToNameMaleRatios < ActiveRecord::Migration
  def change
    add_column :name_male_ratios, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :name_male_ratios, :uuid, unique: true
  end
end
