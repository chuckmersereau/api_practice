class AddContactLocaleToMailChimpMembers < ActiveRecord::Migration
  def change
    add_column :mail_chimp_members, :contact_locale, :string
  end
end
