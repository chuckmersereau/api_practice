class AddTntFieldsToAppeals < ActiveRecord::Migration
  def change
    add_column :appeals, :active, :boolean, default: true
    add_column :appeals, :monthly_amount, :decimal
  end
end
