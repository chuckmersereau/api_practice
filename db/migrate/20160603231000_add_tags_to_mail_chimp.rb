class AddTagsToMailChimp < ActiveRecord::Migration
  def change
    change_table :mail_chimp_accounts do |t|
      t.rename :grouping_id, :status_grouping_id
      t.string :tags_grouping_id
      t.text :tags_interest_ids
    end
  end
end
