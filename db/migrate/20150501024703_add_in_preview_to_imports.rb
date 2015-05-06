class AddInPreviewToImports < ActiveRecord::Migration
  def change
    add_column :imports, :in_preview, :boolean, null: false, default: false
  end
end
