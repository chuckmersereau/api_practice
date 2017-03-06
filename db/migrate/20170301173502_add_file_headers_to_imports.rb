class AddFileHeadersToImports < ActiveRecord::Migration
  def change
    add_column :imports, :file_headers, :text
  end
end
