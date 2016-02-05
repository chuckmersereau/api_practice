class AddIndexToTagsLowerName < ActiveRecord::Migration
  self.disable_ddl_transaction!
  def change
    execute "create index concurrently tags_on_lower_name
             on tags(lower(name));"
  end
end
