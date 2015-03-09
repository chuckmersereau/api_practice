class AddTntIdToAppeals < ActiveRecord::Migration
  def change
    add_column :appeals, :tnt_id, :integer
  end
end
