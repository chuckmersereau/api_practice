class ChangeRemoteIdOnActivitiesToText < ActiveRecord::Migration
  def up
    change_column :activities, :remote_id, :text
  end

  def down
    change_column :activities, :remote_id, :string
  end
end
