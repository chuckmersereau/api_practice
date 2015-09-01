class AddAutoLogCampaignsToMailChimpAccount < ActiveRecord::Migration
  def change
    add_column :mail_chimp_accounts, :auto_log_campaigns, :boolean, null: false, default: false
  end
end
