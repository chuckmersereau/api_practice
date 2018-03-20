class ChangePersonOptionsValueToText < ActiveRecord::Migration
  def change
    change_column :person_options, :value, :text
  end
end
