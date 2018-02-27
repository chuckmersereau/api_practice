class AddColumnsForPrefBlogForeignKeys < ActiveRecord::Migration
  def change
    add_column :people, :default_account_list_id_holder, :integer
    add_column :account_lists, :salary_organization_id_holder, :integer
  end
end
