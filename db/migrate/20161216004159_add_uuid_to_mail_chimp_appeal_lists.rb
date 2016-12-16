class AddUuidToMailChimpAppealLists < ActiveRecord::Migration
  def change
    add_column :mail_chimp_appeal_lists, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :mail_chimp_appeal_lists, :uuid, unique: true
  end
end
