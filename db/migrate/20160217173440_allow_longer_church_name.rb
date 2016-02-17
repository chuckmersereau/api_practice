class AllowLongerChurchName < ActiveRecord::Migration
  def change
    change_column :contacts, :church_name, :text
  end
end
