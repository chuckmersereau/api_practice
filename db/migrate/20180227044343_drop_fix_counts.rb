class DropFixCounts < ActiveRecord::Migration
  def change
    drop_table :fix_counts
  end
end
