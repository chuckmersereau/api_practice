class GaNotificationFailure < ActiveRecord::Migration
  def change
    add_column :person_google_accounts, :notified_failure, :boolean
  end
end
