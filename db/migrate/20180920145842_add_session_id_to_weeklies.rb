class AddSessionIdToWeeklies < ActiveRecord::Migration
  def change
    add_column :weeklies, :session_id, :integer
  end
end
