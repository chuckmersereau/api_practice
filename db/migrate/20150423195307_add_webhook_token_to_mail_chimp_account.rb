class AddWebhookTokenToMailChimpAccount < ActiveRecord::Migration
  def change
    add_column :mail_chimp_accounts, :webhook_token, :string
  end
end
