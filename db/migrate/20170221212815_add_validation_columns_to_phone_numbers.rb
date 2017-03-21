class AddValidationColumnsToPhoneNumbers < ActiveRecord::Migration
  def change
    add_column :phone_numbers, :valid_values, :boolean, default: true
    add_column :phone_numbers, :source, :string, default: 'MPDX'
  end
end
