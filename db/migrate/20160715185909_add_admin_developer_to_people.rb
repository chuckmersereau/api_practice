class AddAdminDeveloperToPeople < ActiveRecord::Migration
  def change
    add_column :people, :admin, :boolean, :default => false
    add_column :people, :developer, :boolean, :default => false
  end
end
