class AddForeignKeyToPeronOnMasterPerson < ActiveRecord::Migration
  def change
    add_foreign_key(:people, :master_people, dependent: :restrict)
  end
end
