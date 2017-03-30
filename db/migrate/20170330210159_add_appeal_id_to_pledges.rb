class AddAppealIdToPledges < ActiveRecord::Migration
  def change
    add_column :pledges, :appeal_id, :integer
    add_index :pledges, :appeal_id
  end
end
