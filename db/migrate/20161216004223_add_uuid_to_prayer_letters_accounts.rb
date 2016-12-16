class AddUuidToPrayerLettersAccounts < ActiveRecord::Migration
  def change
    add_column :prayer_letters_accounts, :uuid, :uuid, null: false, default: 'uuid_generate_v4()'
    add_index :prayer_letters_accounts, :uuid, unique: true
  end
end
