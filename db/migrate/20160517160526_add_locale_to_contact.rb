class AddLocaleToContact < ActiveRecord::Migration
  def change
    add_column :contacts, :contact_locale, :string
  end
end
