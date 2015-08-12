class CreateMailChimpAppealLists < ActiveRecord::Migration
  def change
    create_table :mail_chimp_appeal_lists do |t|
      t.integer :mail_chimp_account_id, null: false
      t.string :appeal_list_id, null: false
      t.integer :appeal_id, null: false

      t.timestamps
    end
    add_index :mail_chimp_appeal_lists, :mail_chimp_account_id
    add_index :mail_chimp_appeal_lists, :appeal_list_id
  end
end
