class AddPrimaryAppealToAccountLists < ActiveRecord::Migration
  def change
    add_column :account_lists, :primary_appeal_id, :integer
  end
end
