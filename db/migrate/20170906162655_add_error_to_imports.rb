class AddErrorToImports < ActiveRecord::Migration
  def change
    add_column :imports, :error, :text
  end
end
