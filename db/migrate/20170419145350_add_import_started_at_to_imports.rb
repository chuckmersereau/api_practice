class AddImportStartedAtToImports < ActiveRecord::Migration
  def change
    add_column :imports, :import_started_at, :datetime
  end
end
