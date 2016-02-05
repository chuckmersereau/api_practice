class AddIndexToGoogleEmailsIds < ActiveRecord::Migration
  self.disable_ddl_transaction!
  def change
    add_index :google_emails, [:google_account_id, :google_email_id], algorithm: :concurrently
  end
end
