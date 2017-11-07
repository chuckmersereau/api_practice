class AddInterestsDetailsToMailChimpAccounts < ActiveRecord::Migration
  def change
    add_column :mail_chimp_accounts, :tags_details, :text
    add_column :mail_chimp_accounts, :statuses_details, :text
  end
end
