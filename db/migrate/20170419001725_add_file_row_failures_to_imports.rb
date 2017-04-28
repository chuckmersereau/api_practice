class AddFileRowFailuresToImports < ActiveRecord::Migration
  def change
    add_column :imports, :file_row_failures, :text
  end
end
