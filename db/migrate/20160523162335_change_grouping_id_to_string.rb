class ChangeGroupingIdToString < ActiveRecord::Migration
  def change
    change_column :mail_chimp_accounts, :grouping_id, :string
  end
end
