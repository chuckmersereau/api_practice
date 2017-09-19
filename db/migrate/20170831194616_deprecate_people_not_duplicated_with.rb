class DeprecatePeopleNotDuplicatedWith < ActiveRecord::Migration
  def change
    rename_column :people, :not_duplicated_with, :deprecated_not_duplicated_with
  end
end
