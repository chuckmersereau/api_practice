class AddImportCompletedAtToImports < ActiveRecord::Migration
  def change
    add_column :imports, :import_completed_at, :datetime
  end
end
