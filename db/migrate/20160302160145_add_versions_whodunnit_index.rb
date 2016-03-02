class AddVersionsWhodunnitIndex < ActiveRecord::Migration
  self.disable_ddl_transaction!
  def change
    add_index :versions, :whodunnit, algorithm: :concurrently
  end
end
