class AddNoDueDateToActivity < ActiveRecord::Migration
  def change
    add_column :activities, :no_date, :boolean
  end
end
