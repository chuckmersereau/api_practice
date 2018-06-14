class ChangeDeletedOn < ActiveRecord::Migration
  def change
    rename_column :deleted_records, :deleted_on, :deleted_at
  end
end
