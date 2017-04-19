class AddQueuedForImportAtToImports < ActiveRecord::Migration
  def change
    add_column :imports, :queued_for_import_at, :datetime
  end
end
