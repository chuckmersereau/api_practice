class AddFileConstantsAndMappingsFieldsToImports < ActiveRecord::Migration
  def change
    add_column :imports, :file_constants, :text
    add_column :imports, :file_headers_mappings, :text
    add_column :imports, :file_constants_mappings, :text
  end
end
