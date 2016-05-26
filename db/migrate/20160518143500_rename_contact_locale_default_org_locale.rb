class RenameContactLocaleDefaultOrgLocale < ActiveRecord::Migration
  def change
    rename_column :contacts, :contact_locale, :locale
    change_column :organizations, :locale, :string, null: false, default: 'en'
  end
end
