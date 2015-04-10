class AddPrayerLettersParamsToContacts < ActiveRecord::Migration
  def change
    add_column :contacts, :prayer_letters_params, :text
  end
end
