class AddHistoricToPhoneNumbers < ActiveRecord::Migration
  def change
    add_column :phone_numbers, :historic, :boolean, default: false
  end
end
