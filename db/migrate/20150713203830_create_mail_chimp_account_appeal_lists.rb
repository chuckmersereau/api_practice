class CreateMailChimpAccountAppealLists < ActiveRecord::Migration
  def change
    create_table :mail_chimp_account_appeal_lists do |t|
      t.integer :mail_chimp_account_id
      t.integer :appeal_list_id
      t.integer :appeal_id

      t.timestamps
    end
    add_index :mail_chimp_account_appeal_lists, :mail_chimp_account_id
    add_index :mail_chimp_account_appeal_lists, :appeal_list_id
  end
end
