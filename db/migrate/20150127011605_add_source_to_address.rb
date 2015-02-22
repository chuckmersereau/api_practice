class AddSourceToAddress < ActiveRecord::Migration
  def change
    add_column :addresses, :source, :string
  end
end
