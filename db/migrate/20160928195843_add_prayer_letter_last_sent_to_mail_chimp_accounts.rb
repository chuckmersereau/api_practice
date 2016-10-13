class AddPrayerLetterLastSentToMailChimpAccounts < ActiveRecord::Migration
  def change
    add_column :mail_chimp_accounts, :prayer_letter_last_sent, :datetime
  end
end
