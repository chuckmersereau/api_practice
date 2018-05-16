class RemoveNoDateFromActivities < ActiveRecord::Migration
  def change
    remove_column :activities, :no_date
  end
end
