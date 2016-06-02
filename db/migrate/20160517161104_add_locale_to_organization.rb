class AddLocaleToOrganization < ActiveRecord::Migration
  def change
    add_column :organizations, :locale, :string
  end
end
