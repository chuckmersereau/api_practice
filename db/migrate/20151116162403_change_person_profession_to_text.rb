class ChangePersonProfessionToText < ActiveRecord::Migration
  def change
    change_column :people, :profession, :text
  end
end
