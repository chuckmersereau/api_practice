class DeprecateContactsNotDuplicatedWith < ActiveRecord::Migration
  def change
    rename_column :contacts, :not_duplicated_with, :deprecated_not_duplicated_with
  end
end