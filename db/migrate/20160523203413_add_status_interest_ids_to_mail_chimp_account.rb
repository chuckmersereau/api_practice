class AddStatusInterestIdsToMailChimpAccount < ActiveRecord::Migration
  def change
    add_column :mail_chimp_accounts, :status_interest_ids, :text
  end
end
