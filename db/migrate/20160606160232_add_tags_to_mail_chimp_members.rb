class AddTagsToMailChimpMembers < ActiveRecord::Migration
  def change
    add_column :mail_chimp_members, :tags, :string, array: true
  end
end
