class AddMpdSeasonToAccountLists < ActiveRecord::Migration
  def change
    add_column :account_lists, :active_mpd_start_at, :date
    add_column :account_lists, :active_mpd_finish_at, :date
    add_column :account_lists, :active_mpd_monthly_goal, :decimal
  end
end
