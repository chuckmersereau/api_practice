class AddFileRowSampesToImports < ActiveRecord::Migration
  def change
    add_column :imports, :file_row_samples, :text
  end
end
